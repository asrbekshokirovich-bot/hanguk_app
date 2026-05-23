# Telegram bot integration audit — 2026-05-23

Scope: every place in the Hanguk Flutter app (`hanguk_app`), the shared
Supabase backend, and (by inference) the React staff CRM
(`hanguk-uz`) that touches the **Telegram Bot API ecosystem** —
inbound updates, message storage, staff inbox, outbound replies,
account-linking flows, lead capture, media handling.

Method: code-first read of every Telegram-referencing surface in
this repo and on the shared Supabase project (`lysjdtyanhdfphqyijsr`,
prod). Direct inspection via Supabase MCP of the deployed
`telegram-webhook` Edge Function source, the `messages` /
`message_threads` / `leads` schemas, their RLS policies, the
`increment_thread_unread` RPC, and the `command-center-webhook`
companion function. Web research second.

Reporting structure (mirrors `kakaotalk_audit_2026-05-11.md`):

  - **Section 1 — What's actually in the code today** (factual inventory)
  - **Section 2 — What perfect looks like** (best-practice research)
  - **Section 3 — Prioritized backlog** (P0/P1/P2 with file/line refs)

Branch: `claude/crm-integrations-analysis-aRzDZ`.
Sister scope: `docs/audits/kakaotalk_audit_2026-05-11.md` and the
forthcoming voice-PBX audit (OATS.uz vendor decision pending operator
phone-validation on Monday 2026-05-25).

---

## Status banner (2026-05-23)

  - **No production Telegram bot is connected.** Per operator
    confirmation in this session, no `@username_bot` has been created
    in BotFather and no webhook URL has been registered with Telegram.
    The `messages` table holds **0 rows** on prod.
  - **The `telegram-webhook` Edge Function is deployed and ACTIVE**
    (slug `001a3307-112d-4cdb-9af6-67750b950afa`, version 14,
    `verify_jwt=false`). Source last updated 2026-04-02 (ezbr sha
    `e04db826…`). It is orphaned: receives no traffic because no
    webhook is registered upstream.
  - **No `telegram-send` Edge Function exists.** Staff cannot reply
    via Telegram even if they could read inbound messages — the
    loop is one-way by construction.
  - **The Flutter app `hanguk_app` has no Telegram surface at all.**
    `lib/features/chat/` is the **Hanguk AI** assistant (Gemini-backed,
    via the `hanguk-ai-chat` Edge Function) — NOT a Telegram bridge.
    Do not repurpose it.
  - **The staff inbox UI lives in the separate `hanguk-uz` React
    repo** and is not visible from this codebase. The `Messages`
    React context referenced in
    `docs/runbooks/hanguk-uz-staff-crm-architecture.md` line 22 is
    the consumer of `public.messages` / `public.message_threads`.
    All claims about staff-side rendering in this audit are
    inferred from schema shape, not verified.

---

## Executive summary

The Telegram integration is a **half-deployed MVP that has never been
turned on**. The schema is in good shape (multi-channel by design),
the inbound webhook function exists, and the thread-upsert RPC is
correct. But:

  1. **Security**: the webhook has **no secret verification**, so
     once it's connected anyone on the internet who finds the URL can
     forge Telegram updates and inject messages into the CRM inbox.
  2. **Correctness**: there is **no idempotency** at the storage layer
     — Telegram retries on any non-2xx and on 60s timeout, and the
     code returns HTTP 500 on DB errors, which guarantees duplicate
     messages once it goes live under load.
  3. **Completeness**: there is **no outbound function**, no `/start`
     handling, no welcome reply, no media handling, no student
     account linking, no lead auto-creation. The end-to-end "DM the
     bot → staff sees → staff replies → user sees the reply" loop
     is impossible today.
  4. **Side finding (not Telegram-specific but discovered here)**:
     the `public.leads` table has an `Allow public select for leads`
     RLS policy with `USING (true)` — any holder of the anon key can
     read every lead row, including `phone`, `password`,
     `contract_number`, `payment_plan`. **This is a data leak**
     regardless of whether Telegram lands. See §1.5 and P0-X1.

This audit's top recommendations are: (1) close the 5 P0 webhook bugs
before any bot is ever connected (T1–T5); (2) write the
`telegram-send` Edge Function so the loop can close (T5); (3) add
the student-linking column + `/start` deep-link flow so known
students don't appear as anonymous leads (T7+T10); (4) fix the
leaky leads RLS policy independently (X1); and (5) follow the
BotFather setup runbook in §3 before flipping the integration on.

---

## Section 1 — What's actually in the code today

### 1.1 Bot identity & runtime configuration

  - **Bot Telegram identity**: none. No `@username` exists per
    operator confirmation. No record of a token having been issued.
  - **Supabase secret `TELEGRAM_BOT_TOKEN`**: presence unverified
    from this side (Supabase MCP does not expose secret values). The
    deployed webhook code reads `Deno.env.get("TELEGRAM_BOT_TOKEN")`
    at boot but, in the current code, only reports it back in the
    GET handler's setup-instructions hint — it is **never used to
    call the Telegram API** (no `sendMessage`, no `getFile`, no
    `setWebhook`). So the secret could be set or unset and the
    inbound path would not care.
  - **Supabase secret `TELEGRAM_WEBHOOK_SECRET`**: the deployed code
    does not reference this. There is no secret verification at
    all. See T1.
  - **Webhook registration with Telegram**: not done (no bot exists).
    When it does, it must point at the Edge Function URL with the
    secret token header path (T1).

### 1.2 Edge Function: `telegram-webhook`

  - Slug: `telegram-webhook`
  - URL (computed):
    `https://lysjdtyanhdfphqyijsr.supabase.co/functions/v1/telegram-webhook`
  - `verify_jwt: false` ✓ (correct — Telegram does not send a JWT)
  - Source file: `supabase/functions/telegram-webhook/index.ts` —
    **not in this repo**; lives in the `hanguk-uz` React repo's
    Supabase functions folder, deployed from there.
  - Version 14, last updated 2026-04-02 by Supabase deploy time
    (~7 weeks before this audit).
  - LOC: ~100. Single-file, no helpers.

**Lifecycle pseudocode (what it does today):**

```
on POST:
  parse JSON body as Telegram Update
  if update.message:
    chatId   = String(message.chat.id)
    senderId = String(message.from.id)         ← CRASHES if no `from` (TG4)
    senderName = (first_name + last_name).trim()
    content = message.text || "[Media message]"  ← media lost (T9)
    rpc('increment_thread_unread', {source:'telegram', sender_id:chatId, sender_name})
    insert into messages {
      source:'telegram',
      external_id: String(message.message_id),
      sender_id: chatId,
      sender_name, content, message_type, direction:'incoming', status:'unread',
      metadata: { telegram_chat_id, telegram_message_id, telegram_user_id },
    }
  return 200 {ok:true}
catch:
  return 500 {error}                           ← guarantees retry storm (T3)

on GET:
  return 200 with "setup_instructions" probe text
```

**P0 bugs visible in this source (annotated above with tag refs):**

| Tag | Bug | Impact |
|---|---|---|
| **T1** | No `X-Telegram-Bot-Api-Secret-Token` header verification. | Anyone who finds the URL can POST forged updates → fake inbox messages, fake "user said X". |
| **T2** | No `UNIQUE(source, external_id)` on `messages` and no `ON CONFLICT` in the insert. | Telegram delivery is at-least-once with retries on 5xx & timeouts; duplicates will accumulate. |
| **T3** | Returns HTTP 500 on caught DB errors. | Telegram retries indefinitely (exponential backoff) → once DB recovers, every retried update is re-inserted. |
| **T4** | Reads `message.from.id` without null-guarding. Many update types (`channel_post`, `edited_channel_post`, sometimes `my_chat_member`) have no `from`. | `TypeError: cannot read 'id' of undefined` → 500 → see T3 retry storm. |
| **T5** | No outbound function. The webhook is the only Telegram code. | Staff inbox is read-only. The product is non-functional until this lands. |

**P1 / P2 issues also visible:**

| Tag | Issue | Surface |
|---|---|---|
| T6 | `chat.id` and `from.id` are JS numbers; for very large Telegram IDs (> 2^53) precision is lost. The code stringifies via `.toString()` which is safer than implicit cast, but it should ideally read from the raw JSON string before `JSON.parse` strips precision. Low practical risk today; documenting. | `index.ts` chatId/senderId derivation. |
| T7 | No `/start` command handling. | (entire `if (update.message)` block) |
| T8 | No reply ever sent. Users message into a void. | (no `sendMessage` call anywhere) |
| T9 | Media (photo / voice / document / video / sticker / location / contact / poll) is collapsed to literal `"[Media message]"`. No `getFile`, no URL, no caption capture, no Storage upload. | `content = message.text \|\| "[Media message]"` |
| T10 | `messages.student_id` is never populated. No lookup against `profiles` to identify a known student. | (no profile lookup in insert path) |
| T11 | No `leads` row is created for unknown senders. Inbound prospects are invisible to the lead-conversion funnel. | (no `leads` insert) |
| T12 | No `callback_query` handling. Inline-keyboard button presses are silently dropped. | (no `else if (update.callback_query)`) |
| T13 | No commands menu (`/help`, `/menu`, `/contact`) set via `setMyCommands`. | (no setup script) |
| T14 | No localization. Bot will never reply in Uzbek/Russian/Korean. | (no i18n surface) |
| T15 | No `edited_message` handling — edits arrive as new updates and get dropped. | (no `else if (update.edited_message)`) |
| T16 | No abuse / rate limiting / spam protection. | (no per-sender throttling) |
| T17 | Observability is `console.log` only — no structured logging, no error reporting to Sentry/Logflare. | (throughout) |
| T18 | The `metadata` jsonb stores `telegram_chat_id`, `telegram_message_id`, `telegram_user_id` but **also** these are split across `sender_id` and `external_id` columns — duplication that the React-side queries may not expect. | message insert object. |

### 1.3 Edge Function: `telegram-send` — **does not exist**

There is no deployed function for outbound Telegram messages. The
React CRM's `Messages` context (per the architecture doc) can read
threads/messages, but has no server endpoint to deliver a staff
reply back to Telegram. This is the single biggest gap.

What it needs to do (see §2 and T5 backlog):
  - Accept `{thread_id | sender_id, text, reply_to_message_id?}`
  - Auth via the staff JWT (`verify_jwt: true`), check
    `has_role(auth.uid(), 'owner' | 'admin' | 'call_operator')`
  - Call Telegram Bot API `sendMessage` with the bot token
  - On success: insert `messages` row with `direction='outgoing'`,
    `external_id` = Telegram's returned message_id, `replied_by` =
    `auth.uid()`; also update the inbound row's `replied_at` and the
    thread's `last_message_at` + reset `unread_count`.

### 1.4 Schema surface

The `public.messages` / `public.message_threads` / `public.leads`
schema is **multi-channel by design** — Telegram is one of several
sources the design anticipated. Schema is in `00000000000001_lovable_baseline.sql`
lines 906–948.

```sql
public.messages (
  id uuid PK,
  source text NOT NULL  CHECK source IN ('telegram','instagram','whatsapp','manual'),
  external_id text,                              -- the platform's message id
  sender_id text,                                -- the platform's user/chat id
  sender_name text, sender_avatar text,
  content text NOT NULL,
  message_type text DEFAULT 'text'  CHECK IN ('text','image','file','voice'),
  direction text DEFAULT 'incoming' CHECK IN ('incoming','outgoing'),
  status text DEFAULT 'unread'      CHECK IN ('unread','read','replied','archived'),
  student_id uuid NULL,                          -- never populated today (T10)
  assigned_to uuid NULL,
  replied_by uuid NULL, replied_at timestamptz NULL,
  metadata jsonb NULL,
  created_at timestamptz NOT NULL DEFAULT now()
)
-- Indexes: pkey(id), idx_messages_source(source), idx_messages_sender_id(sender_id)
-- ❌ MISSING: UNIQUE(source, external_id)  ← idempotency gap (T2)
-- ❌ MISSING: thread_id FK  ← joins via (source, sender_id) instead

public.message_threads (
  id uuid PK,
  source text NOT NULL,
  sender_id text NOT NULL,
  sender_name text, sender_avatar text,
  student_id uuid NULL,
  last_message_at timestamptz NOT NULL DEFAULT now(),
  unread_count int NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'active'  CHECK IN ('active','archived'),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (source, sender_id)                     -- ✓ correct conversation key
)

public.leads (... 30+ columns including phone,email,city,birth_date,
  preferred_university, preferred_program, budget_range, korean_level,
  source text DEFAULT 'manual', source_id text, status text DEFAULT 'new',
  password text, login_count int, login_history text[] ...)
```

The accompanying RPC `public.increment_thread_unread(p_source,
p_sender_id, p_sender_name)` is `SECURITY DEFINER` with
`search_path = 'pg_catalog','public'`, body:

```sql
INSERT INTO message_threads (source, sender_id, sender_name,
                             last_message_at, unread_count, status)
VALUES (p_source, p_sender_id, p_sender_name, now(), 1, 'active')
ON CONFLICT (source, sender_id) DO UPDATE SET
  unread_count   = message_threads.unread_count + 1,
  last_message_at = now(),
  sender_name    = EXCLUDED.sender_name;
```

This is **correctly atomic** and avoids the upsert-then-update race.
Only nit: it does not allow specifying an avatar; T18 cleanup could
extend it to accept `p_sender_avatar`.

**Gaps in the schema that block Phase 1:**

| Tag | Gap | Migration needed |
|---|---|---|
| T2 | No `UNIQUE(source, external_id)` on `messages` for idempotent inserts. | New migration: partial unique index `WHERE external_id IS NOT NULL`. |
| T19 | No `telegram_chat_id` column on `profiles` to link a logged-in student to their Telegram identity. | Add `telegram_chat_id text UNIQUE`, plus an index. |
| T20 | No `telegram_link_tokens` table for the deep-link claim flow. | New table: `(token text PK, profile_user_id uuid, expires_at timestamptz, used_at timestamptz null)`. |
| T21 | `messages.source` CHECK does not include `'phone'`, `'email'`, `'kakao'`. The OATS / phone work will need it extended. | Drop-and-recreate the check, or replace with FK to a `message_sources` reference table. |

### 1.5 RLS surface

`messages` and `message_threads` are correctly locked to staff roles
(owner / admin / call_operator for write; +document_handler for
read). The webhook bypasses RLS using
`SUPABASE_SERVICE_ROLE_KEY` — correct.

`leads` has a **leaky read policy that is unrelated to Telegram but
was discovered during this audit**:

| Policy on `public.leads` | Cmd | USING / CHECK |
|---|---|---|
| `Allow public select for leads` | `SELECT` | `USING (true)` ⚠️ |
| `Allow public insert for leads` | `INSERT` | `CHECK (true)` (likely intentional for public lead-capture forms) |
| `Staff can view all leads` | `SELECT` | role check (correct) |
| `Staff can create leads` | `INSERT` | role check (correct) |
| `Staff can update leads` | `UPDATE` | role check (correct) |
| `Admins can delete leads` | `DELETE` | role check (correct) |

Because RLS policies are OR-combined per command, the `USING (true)`
SELECT means **any caller with the anon key — i.e. anyone reading the
React app's Network tab in DevTools — can `select * from leads`** and
get full PII: phone, password, contract_number, payment_plan,
budget_range, birth_date, login_history. **Flagged as P0-X1 below**;
should be fixed independently of the Telegram work.

### 1.6 The Flutter app's relationship to Telegram (none)

  - `lib/features/chat/` is the **Hanguk AI** assistant, calling the
    `hanguk-ai-chat` Gemini Edge Function. Specifically:
    - `lib/features/chat/data/chat_repository.dart:63` POSTs to
      `https://lysjdtyanhdfphqyijsr.supabase.co/functions/v1/hanguk-ai-chat`
    - `lib/features/chat/presentation/chat_tab.dart:58` titles it
      `Hanguk AI`. Hint text on the input is
      `"Ask anything about South Korea..."`.
    - This is unrelated to Telegram and **must not be reused** as
      the Telegram surface — the data model, semantics, and intent
      are different (single-user AI Q&A vs. multi-party
      staff↔student chat).
  - No deep-link handler exists for `tg://resolve?domain=...`,
    `https://t.me/...`, or for the inbound `/start?token=...`
    return from Telegram. The `lib/core/router/app_router.dart`
    surface needs a new route for "Linked Telegram!" confirmation
    (T10).
  - No `flutter_telegram_*` package in `pubspec.yaml`. Not needed
    — Telegram from a mobile app is best done via OS deep-link, not
    SDK.
  - The Flutter app already ships push notifications
    (`register-push-token`, `notify-tracked-changes`,
    `user_push_tokens` table) — so notification-via-Telegram is a
    P2 additive channel, not a replacement.

### 1.7 Cross-repo observations

The staff inbox UI is **not in this repo**. Per
`docs/runbooks/hanguk-uz-staff-crm-architecture.md`:

  - The CRM is React + Vite + shadcn/ui, deployed to `hanguk.uz`.
  - It has a `Messages` React context already wired (line 22).
  - It has a `Leads` React context and a `LeadsContent.tsx` page
    (lines 22, 55).
  - The Supabase Edge Functions deployed from the React repo
    include the `telegram-webhook` function under audit here.

This audit **cannot verify** that the CRM actually renders inbound
Telegram threads — I cannot read the `hanguk-uz` source from this
session (GitHub MCP scope is restricted to `hanguk_app`). Open
question OQ-1 below.

### 1.8 Adjacent Edge Functions worth noting

Found while inventorying, included here for situational awareness:

| Function | Purpose | Relevance to Telegram |
|---|---|---|
| `command-center-webhook` | External "Command Center" syncs tasks/transactions/workers into Supabase via `BCC_API_KEY`. Has proper `x-api-key` auth — **the right pattern to mirror for T1**. | Pattern reference for secret-header auth. |
| `voip-webhook` | (Not inspected this pass.) Presumably the inbound-side hook for the SIP/cloud-PBX integration. Will pair with the OATS work. | Sibling integration. |
| `analyze-lead` / `leads-intelligence` | AI scoring of incoming leads (per their names + the `leads.ai_summary` / `priority_score` fields). | Likely consumes the same `leads` rows we should auto-create from Telegram (T11). Need to verify schema expectations. |
| `sync-to-command-center` | Outbound mirror of the above — pushes Supabase state back. | Out of Telegram scope but flagged. |

Also relevant from `profiles`:

| Profile field | Why it matters |
|---|---|
| `sip1_user`, `sip1_password`, `sip1_server`, `sip1_port`, `sip1_label`, plus `sip2_*` | Each staff member has dual SIP softphone credentials. Implies an existing SIP softphone surface in the CRM. The OATS work in two weeks will need to either reuse this or extend it. |
| `marketing_consent`, `marketing_consent_at` | Required by Telegram BCM best practice — store consent at the moment they grant it, do not use as a default. |
| `preferred_language` | Use to localize bot replies (T14). |

---

## Section 2 — What perfect looks like

### 2.1 Telegram webhook best practices (current Bot API)

  - **Always verify the secret token**. When calling `setWebhook`,
    pass `secret_token: <random 256-bit hex>` and on every inbound
    request check the `X-Telegram-Bot-Api-Secret-Token` header equals
    that value. Reject 401 if not. (Telegram docs:
    [setWebhook](https://core.telegram.org/bots/api#setwebhook).)
  - **Always respond within 60 seconds**. The Telegram server will
    retry the same update on timeout or non-2xx. Do **not** do slow
    work inline; queue it (Supabase Realtime, pg_cron, or a separate
    background function via `EdgeRuntime.waitUntil`).
  - **Always return 2xx**, even on internal errors. Log and move on;
    return 500 only when you genuinely want the update redelivered.
    (Bot API spec — same page above.)
  - **Idempotency** at the storage layer: dedupe on
    `(bot_id, update_id)` or `(chat_id, message_id)`. With `UNIQUE
    (source, external_id) ON CONFLICT DO NOTHING` the database
    becomes the source of truth and retries are no-ops.
  - **One bot, one webhook URL**. If you need development +
    production, use two bots, not URL routing.
  - **HTTPS only**, leaf cert valid, allowlist Telegram IP ranges if
    on a paranoid network (Supabase Edge does not need this; it's
    fronted by Cloudflare).

### 2.2 Two-way conversation pattern

```
[student app/Telegram] ──(text)──▶ Telegram cloud
                                       │
                                       ▼
                              telegram-webhook (Supabase Edge)
                                       │
                                       │ 1. verify secret header
                                       │ 2. lookup profile by telegram_chat_id
                                       │ 3. INSERT messages ON CONFLICT DO NOTHING
                                       │ 4. CALL increment_thread_unread
                                       │ 5. IF unknown sender AND no thread:
                                       │      INSERT leads (source='telegram',...)
                                       │ 6. emit Realtime event on messages channel
                                       ▼
                              Supabase Realtime
                                       │
                                       ▼
                              React CRM Messages inbox      ──(staff types reply)──┐
                                                                                    │
                                                                                    ▼
                                                                       telegram-send (Edge)
                                                                                    │
                                                                                    │ 1. verify staff JWT + role
                                                                                    │ 2. POST sendMessage to Telegram
                                                                                    │ 3. INSERT messages direction='outgoing'
                                                                                    │ 4. UPDATE thread (last_message_at,unread=0)
                                                                                    │ 5. UPDATE inbound replied_at, replied_by
                                                                                    ▼
                                                                            Telegram cloud
                                                                                    │
                                                                                    ▼
                                                                            [student app/Telegram]
```

### 2.3 Student account linking via `/start` deep link

For students already enrolled (in `profiles`), the Flutter app must
let them claim their Telegram identity so future messages are
attributed (and visible in the staff CRM under their student record).

```
Flutter app (logged-in student):
  Settings → "Connect Telegram"
    → POST to telegram-link function
    → server generates token = random_url_safe(24)
    → INSERT INTO telegram_link_tokens (token, profile_user_id, expires_at=now()+10min)
    → returns deep-link URL:  https://t.me/<bot_username>?start=<token>
    → opens in OS-installed Telegram app

User taps "START":
  → Telegram sends to bot:  /start <token>
  → telegram-webhook receives update.message with text starting "/start "
  → extract token, SELECT FROM telegram_link_tokens WHERE token=? AND used_at IS NULL AND expires_at>now()
  → IF valid: UPDATE profiles SET telegram_chat_id = chat_id WHERE user_id = token.profile_user_id;
            mark token used;
            sendMessage("✅ Your account is linked, {name}. We'll keep in touch here.")
  → IF invalid: sendMessage("This link expired. Open the app and try again.")
```

### 2.4 Lead capture for unknown senders

When a sender's `telegram_chat_id` matches no `profiles` row,
the first message creates a `leads` row:

```
IF no thread AND no matching profile:
  INSERT INTO leads (full_name, source, source_id, status, notes)
  VALUES (sender_name, 'telegram', chat_id, 'new',
          'First contact via Telegram: '||truncate(content,200));
  thread.metadata = { lead_id: <returned id> };
```

This wires up the existing `leads-intelligence` and `analyze-lead`
AI scoring functions to act on real inbound prospects.

### 2.5 Multi-channel inbox UX (for the React side)

The schema correctly anticipates multiple channels (`source` enum).
Best-in-class inbox renders:

  - One thread list keyed by `(source, sender_id)` with channel
    icon, last message, unread badge, assigned staff avatar.
  - Per-thread message stream with `direction` rendered as left/right
    bubbles; `status='replied'` shown as a tick.
  - "Reply" composer calls `telegram-send` (or `instagram-send`,
    `whatsapp-send`, `phone-callback`) based on `thread.source`.
  - Realtime updates via Supabase Realtime on `messages` and
    `message_threads`.

This is out of scope for this Flutter-repo audit; flagged for the
`hanguk-uz` repo work.

---

## Section 3 — Prioritized backlog

Numbering: **T**-prefixed for Telegram-specific items, **X**-prefixed
for unrelated findings that surfaced.

### P0 — security + correctness (must close before any bot is ever connected)

| ID | Action | Where | Notes |
|---|---|---|---|
| **T1** | Add `X-Telegram-Bot-Api-Secret-Token` header verification at top of POST handler. Pull from new `TELEGRAM_WEBHOOK_SECRET` env. Reject 401 if missing/mismatch. | `supabase/functions/telegram-webhook/index.ts` in `hanguk-uz` repo. | Pattern reference: `command-center-webhook` lines 19-31 (`x-api-key` check). Set secret value to a 256-bit hex during `setWebhook` call. |
| **T2** | Add `UNIQUE(source, external_id) WHERE external_id IS NOT NULL` partial index on `public.messages`. Switch webhook insert to `.upsert(..., { onConflict: 'source,external_id', ignoreDuplicates: true })`. | New migration in this repo: `supabase/migrations/2026XXXXXXXXXX_messages_idempotency.sql`. | Partial index because outbound rows have null `external_id` at insert time until `sendMessage` returns. |
| **T3** | On caught errors return HTTP 200 (with logged error). Only return 5xx for cases where you genuinely want redelivery (transient DB outage). | webhook `catch` block. | Avoids retry-storm duplicates once T2 lands; the two go together. |
| **T4** | Null-guard the message-handling branch: `if (update.message?.from && update.message?.chat)`. Add explicit `else if` branches for `update.channel_post`, `update.edited_message`, `update.my_chat_member` (no-op log) so the function never crashes on unknown shapes. | webhook handler. | TS strictness; consider adopting Telegram's official types from `@grammyjs/types`. |
| **T5** | New Edge Function `telegram-send` (`verify_jwt: true`). Accepts `{thread_id, text, reply_to_message_id?}`, calls Telegram `sendMessage`, persists outbound `messages` row, updates thread/inbound markers. | New: `supabase/functions/telegram-send/index.ts`. | Without this, the CRM is a read-only inbox — product non-functional. |
| **X1** | Drop the `Allow public select for leads` RLS policy on `public.leads`. Replace it with a `Public can SELECT only their own lead by id+secret` if a public read pattern is actually needed; otherwise leave staff-only. Coordinate with `hanguk-uz` to ensure no public form relies on this. | Migration in this repo. | **Discovered during the Telegram audit but blocks production confidentiality regardless of Telegram.** |

### P1 — UX completeness (close before user-visible launch)

| ID | Action | Where | Notes |
|---|---|---|---|
| **T6** | (Optional hardening) Parse raw text body and pull ID strings from the JSON before `JSON.parse` to avoid 2^53 precision loss. | Webhook. | Low-likelihood today; Telegram IDs trending toward 2^53. |
| **T7** | Implement `/start [<token>]` command handling. Sends a localized welcome. If token present, run the linking flow (T10). | Webhook + new `telegram_link_tokens` table. | Use `profiles.preferred_language` once the sender is linked; default to UZ. |
| **T8** | Send an auto-ack on every inbound message ("Salom! We've received your message and will reply within X hours."). Make this opt-out at the bot level via a staff toggle in `system_settings`. | Webhook. | UX must distinguish "received" (ack) from "answered" (staff reply). |
| **T9** | Media handling: detect `message.photo/voice/video/document/audio/sticker`, call Telegram `getFile`, upload to Supabase Storage `telegram-media` bucket (private), store the storage path + Telegram file_id in `messages.metadata` and the media type in `message_type`. Set `content` to caption + filename. | Webhook + new storage bucket migration. | Voice messages are essential in UZ; defer transcription to P2 (T17). |
| **T10** | Student account linking flow. Schema: new `telegram_link_tokens` table; new `telegram_chat_id` UNIQUE column on `profiles`. Flow: Flutter Settings → POST to new `telegram-link` Edge → returns `https://t.me/<bot>?start=<token>` → user taps → webhook claims token → flutter app `/telegram/linked` deep-link route confirms success. | Migration + new `telegram-link` Edge Function + Flutter `lib/features/settings/` (new) + `lib/core/router/app_router.dart` route. | Tokens expire 10 min; one-time use; 24-byte URL-safe. |
| **T11** | Lead auto-creation for unknown senders. First inbound message from a `chat_id` that matches no `profiles.telegram_chat_id` AND no existing thread → `INSERT INTO leads (source='telegram', source_id=chat_id, ...)`. Link the thread to the lead via `message_threads.student_id` or a new `lead_id` column. | Webhook. | Coordinate with `analyze-lead` / `leads-intelligence` AI functions — they need to know about the new ingest path. |
| **T12** | `callback_query` (inline-button) handling: if a bot ever uses inline keyboards, queries land here. Wire a minimal switchboard. | Webhook. | Defer concrete buttons until product use-case is decided. |
| **T21** | Extend `messages.source` CHECK to include `'phone'`, `'email'`, `'kakao'` ahead of the OATS work. Better long-term: replace CHECK with FK to a `message_sources(code, label, enabled)` reference table. | Migration. | Required for the cloud-PBX phone work. |

### P2 — polish + observability + cross-channel

| ID | Action | Where | Notes |
|---|---|---|---|
| **T13** | `setMyCommands` on bot startup: `/help`, `/menu`, `/contact`, `/language`. One-off bootstrap script. | New: `scripts/telegram_bot_bootstrap.ts`. |
| **T14** | Localize bot replies (uz/ru/ko/en). Use `profiles.preferred_language` when known; detect from message language otherwise. | Webhook + lib. |
| **T15** | Edited message handling: when `update.edited_message` arrives, UPDATE the matching row by `(source, external_id)` instead of dropping. | Webhook. |
| **T16** | Rate limiting per `sender_id` (e.g. 30 msg / 5 min). Soft response via bot at limit. | Webhook + `messages` count query, or Supabase Edge Rate Limiting. |
| **T17** | Voice-message STT. Pipe the `voice` file through ElevenLabs Scribe (`elevenlabs-scribe-token` Edge Function is already deployed — reuse). Store transcript in `messages.metadata.transcript`. | Webhook (queue lane) + ElevenLabs. |
| **T18** | Extend `increment_thread_unread` RPC to accept `p_sender_avatar text DEFAULT NULL`. Webhook passes Telegram profile photo. Requires `getUserProfilePhotos` + `getFile` + Storage upload. | RPC migration + Webhook. |
| **T19** | Inbound PDF handling (PDF document type — students send admission forms). Mirror T9 media flow but route via `documents` table not `messages` if it looks application-related. | Webhook routing logic. |
| **T22** | Outbound notifications via Telegram (lesson reminders, payment due). Pull from a new `outbound_queue` or piggyback on `change_event_outbox`. Pair with the existing `notify-tracked-changes` cron. | New worker. Phase 3. |
| **T23** | Observability: structured logging (request id, sender id, update type), error reporting to Logflare or Sentry. | Webhook + `telegram-send`. |

### Open questions for the owner (OQs)

  - **OQ-1**: Does the `hanguk-uz` React CRM already render `messages`
    and `message_threads` in a staff inbox UI? If not, that work is
    a hard prerequisite for product launch and lives in the other
    repo. **Action**: read `hanguk-uz/src/components/crm/pages/`
    looking for `MessagesContent.tsx` or similar.
  - **OQ-2**: Should the bot be **silent on first contact** (just log
    the message, staff replies manually) or **send an auto-ack**
    (T8)? Default of this audit: auto-ack is better UX. Confirm.
  - **OQ-3**: For T10 student linking, where in the Flutter app
    should "Connect Telegram" live? Settings is the natural home,
    but there's no `lib/features/settings/` yet — would need to be
    created. Confirm placement.
  - **OQ-4**: For T11 lead auto-creation, should every first contact
    create a lead (high signal, possibly noisy from spam) or only
    contacts that pass a heuristic (sent ≥2 messages, or has
    non-empty profile)? Default: every first contact, with T16
    rate-limiting as the spam filter.
  - **OQ-5**: Bot username — `@hanguk_uz_bot`? `@hanguk_korea_bot`?
    `@hanguk_bot` is likely taken. Operator picks during BotFather
    setup.

### Cross-repo coordination (`hanguk-uz`)

Work that must happen in the React repo, not this one:

  - **C1**: Add the staff inbox UI (Threads list + per-thread
    message stream + reply composer). May already exist; OQ-1.
  - **C2**: Wire the reply composer to call the new `telegram-send`
    Edge Function (T5).
  - **C3**: Move the `telegram-webhook` source file under audit
    here into the `hanguk-uz` Supabase functions folder ownership
    so this audit's P0 fixes land there. (Or move it into THIS
    repo and re-deploy — see C4.)
  - **C4**: **Decide where Telegram Edge Functions live.** Currently
    in `hanguk-uz`. Argument for moving to `hanguk_app`: this audit
    is here, the operator is iterating here, and the CRM work is
    secondary. Argument for keeping in `hanguk-uz`: it's already
    set up there. **My recommendation**: move to this repo, since
    the audits and SQL migrations live here and split ownership is
    a known source of bit-rot.

### BotFather setup runbook (fresh-bot path)

This pairs with the user's "Fresh start" choice on bot status. Walk
through once Monday's OATS validation lands so we don't context-switch.

1. On Telegram, message `@BotFather` → `/newbot`.
2. Name: `HanguK` (or per OQ-5). Username: `hanguk_uz_bot` (try
   alternatives if taken — must end in `_bot`).
3. Copy the token. Format: `1234567890:AAH-XX...`.
4. Run (locally with `supabase` CLI):
   `supabase secrets set TELEGRAM_BOT_TOKEN=<token> --project-ref lysjdtyanhdfphqyijsr`
5. Generate a webhook secret (random 256-bit hex):
   `openssl rand -hex 32`
6. Run:
   `supabase secrets set TELEGRAM_WEBHOOK_SECRET=<hex> --project-ref lysjdtyanhdfphqyijsr`
7. Land the T1+T2+T3+T4+T5 PRs (this audit's P0).
8. Register the webhook with Telegram:
   `curl -F "url=https://lysjdtyanhdfphqyijsr.supabase.co/functions/v1/telegram-webhook" \
         -F "secret_token=<hex>" \
         -F 'allowed_updates=["message","edited_message","callback_query","my_chat_member"]' \
         https://api.telegram.org/bot<token>/setWebhook`
9. Verify: `curl https://api.telegram.org/bot<token>/getWebhookInfo`
   → should show our URL, `pending_update_count: 0`,
   `last_error_message: null`.
10. Optional bot UX: `/setdescription`, `/setabouttext`,
    `/setuserpic`, `/setcommands` via BotFather, OR via API per T13.
11. End-to-end test: from a personal Telegram account DM the bot
    `hello` → confirm a row appears in `messages` and a thread in
    `message_threads` via Supabase MCP.

### Out of scope for this audit

  - The voice-PBX / OATS.uz integration — separate audit, separate
    decision, separate calls Monday 2026-05-25.
  - Telegram Mini App (in-Telegram student portal) — defer to a
    later phase if mobile-app friction proves real.
  - Instagram / WhatsApp Business integrations — schema is ready
    but no Edge Functions exist; out of scope here.
  - The `command-center-webhook` integration with the external BCC
    system — its own thing; only referenced as a pattern for T1.
  - The `voip-webhook` function — sibling to this work; will be
    audited alongside OATS once vendor is chosen.

---

## Appendix A — file/line reference card

| What | Where |
|---|---|
| Deployed `telegram-webhook` source | Not in this repo. Inspect via Supabase MCP `get_edge_function(slug='telegram-webhook')`. SHA `e04db826183d6fc29b71561bd938c97ff947fc0341e4858a2dab2c78afbadf3c`. |
| `messages` / `message_threads` / `leads` DDL | `supabase/migrations/00000000000001_lovable_baseline.sql:906-948` (messages), `:909-925` (threads), `:851-898` (leads). |
| `increment_thread_unread` RPC | `supabase/migrations/00000000000001_lovable_baseline.sql:255-273`. |
| The Flutter Hanguk AI chat (NOT Telegram) | `lib/features/chat/data/chat_repository.dart`, `lib/features/chat/presentation/chat_tab.dart`. |
| CRM architecture reference | `docs/runbooks/hanguk-uz-staff-crm-architecture.md`. |
| KakaoTalk audit precedent (this audit's style sibling) | `docs/audits/kakaotalk_audit_2026-05-11.md`. |
