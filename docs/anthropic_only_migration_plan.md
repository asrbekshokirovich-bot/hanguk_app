# Plan — Anthropic-only AI across Hanguk (app + hanguk.uz website)

_Goal: every AI call in BOTH codebases (the Flutter/uni_db `hanguk_app` repo and
the `hanguk.uz` website/CRM repo) runs on Anthropic (Claude). No Gemini, no
OpenAI — Anthropic everywhere. Headline model **Opus 4.7**; tier within Anthropic
where it makes sense._

## 0. Hard prerequisite (gates every edge function)
- **Set `ANTHROPIC_API_KEY` as a Supabase Edge Function secret** on project
  `lysjdtyanhdfphqyijsr` (Dashboard → Edge Functions → Secrets, or
  `supabase secrets set ANTHROPIC_API_KEY=sk-ant-…`). The CRM currently has **no
  Anthropic key in Supabase** — that's why translate-fields fell back to Gemini.
  Until this is set, every migrated function returns 500/502. **No Claude session
  can set it** (no key value, no secret-management tool) — owner/ops, once.
- The VPS uni_db worker already has its own `ANTHROPIC_API_KEY` (extraction runs
  on Claude today).
- Set an Anthropic **billing cap + usage alerts** before flipping high-volume CRM.

## 1. Inventory — every non-Anthropic AI call
Grep both repos for: `generativelanguage.googleapis.com`, `GEMINI_API_KEY`,
`gemini-`, `openai`, `response_format`.
- **hanguk_app (this repo):** `translate-fields`, `translate-document`
  (Anthropic-primary + Gemini fallback today). uni_db Python worker = already Anthropic.
- **hanguk.uz / CRM (their repo):** `hanguk-ai-chat`, `analyze-lead`,
  `analyze-application-form`, `leads-intelligence`, `compare-universities`,
  `search-university`, `study-plan-trainer`, `validate-application-data`,
  `validate-document`, `find-application-form`, `find-faculty-forms`,
  `discover-university-websites`, … (confirm exact set by grep).
Output: a checklist — function · file · repo · current model.

## 2. Model tiers (within Anthropic)
- **Opus 4.7** (`claude-opus-4-7`) — deep reasoning: lead intelligence,
  application analysis, chat.
- **Sonnet 4.6** (`claude-sonnet-4-6`) — translation, extraction, doc analysis.
- **Haiku 4.5** (`claude-haiku-4-5`) — classification, validation, cheap tagging.
Cost note: Opus ≈ 20–50× gemini-2.5-flash. Tiering keeps quality high and cost
sane. Opus-everywhere is fine if you set a monthly cap — decide per function.

## 3. Shared Anthropic helper (one per repo, reused everywhere)
`callAnthropic({ system, content, model, maxTokens })` → returns text.
- `POST https://api.anthropic.com/v1/messages`; headers `x-api-key`,
  `anthropic-version: 2023-06-01`.
- Body `{ model, max_tokens, system, messages:[{role:"user",content}] }`.
- **No `response_format`** — instruct "return ONLY JSON" in the prompt and parse
  (strip ```fences, extract outermost `{…}`).
- Read `data.content[].text`.
- Multimodal: images → `{type:"image",source:{type:"base64",media_type,data}}`;
  PDFs → `{type:"document",source:{type:"base64",media_type:"application/pdf",data}}`.
- Add 429 retry/backoff (Opus has tighter rate limits than Flash).
Replace each Gemini call site with this helper, then **remove `GEMINI_API_KEY`
usage and the Gemini fallback** → Anthropic-only.

## 4. Rollout (low-risk waves; end state has zero Gemini)
- **Wave 0** — after the key is set: migrate the two in this repo
  (`translate-fields`, `translate-document`) to Anthropic-only (drop the Gemini
  fallback). Verify each returns 200 + good output.
- **Wave 1** — CRM high-value: `hanguk-ai-chat`, `leads-intelligence`,
  `analyze-application-form`.
- **Wave 2** — remaining CRM: validate / find / discover / compare / search.
- Keep a short-lived Anthropic→Gemini fallback during each wave so a bad
  key/model never takes a feature down; **delete the Gemini path once stable**.
- **Done =** grep finds **zero** Gemini references in either repo; the
  `GEMINI_API_KEY` secret can be removed.
- uni_db worker: set `ANTHROPIC_MODEL_EXTRACT=claude-opus-4-7` (or keep Sonnet) in
  the VPS env — needs the pending VPS deploy.

## 5. Verify & monitor
- Each migrated function: a real call → 200 with good output.
- Watch Supabase edge logs for 4xx/5xx and the Anthropic dashboard for cost and
  429 (rate-limit) spikes.

## 6. Ownership
- **Me (hanguk_app repo):** `translate-fields`, `translate-document` + the worker
  model string.
- **hanguk.uz / CRM team (their repo):** all CRM functions, using the §3 helper.

---
**The single unblock for all of this: set `ANTHROPIC_API_KEY` in Supabase.** The
moment it's set, Wave 0 (this repo's two functions → Anthropic-only) can ship and
be verified.
