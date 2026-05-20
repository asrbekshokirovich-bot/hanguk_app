# Hanguk University Database — full handoff document

**Generated:** 2026-05-14 by the prior session.
**For:** the next Claude agent picking up uni_db work.
**Companion files:** `00_PROMPT.md`, `CREDENTIALS_REFERENCE.md`, `NEXT_STEPS.md` (in this same directory).

---

## 1. One-paragraph project overview

Hanguk is a Flutter mobile app that helps Uzbek students apply to Korean universities. The "university database" subsystem (`uni_db`) is the back-end that crawls Korean admissions boards (`.ac.kr`), parses guideline PDFs, runs LLM extraction with HITL review, translates Korean source into the languages Hanguk users read, and exposes the structured result to the Flutter app via Supabase. **The system is fully implemented across 4 phases (0/1/2/3) — code is shipped, schema is on production, the Flutter app is wired and has its feature flag flipped on.** The missing piece is operational: live Korean crawls have never run because per-university CSS selectors weren't written and no worker was running 24/7. The previous session set up the worker host (Hetzner CX23 in Falkenstein) and got everything except the selector configs ready.

## 2. Architecture (3 layers)

```
┌────────────────────────────────────────────────────────────────┐
│ Flutter app  (lib/features/uni_db/, kUniDbEnabled=true)        │
│ - /admin/review (HITL reviewer queue)                          │
│ - /institutions/compare                                        │
│ - /institutions/<id> (rich detail)                             │
│ - VerifiedDeadlineCard, RecentChangesBanner, etc.              │
└────────────────┬───────────────────────────────────────────────┘
                 │ Supabase JS SDK (PostgREST + RPC)
                 │ + anon key from app_config.dart
┌────────────────▼───────────────────────────────────────────────┐
│ Supabase project lysjdtyanhdfphqyijsr ("Hanguk 2026")          │
│ - 38 uni_db migrations applied                                 │
│ - institutions, recruitment_units, requirements, tuition,      │
│   scholarships, documents_required, guideline_documents,       │
│   announcements, announcement_sources, review_queue,           │
│   translations, user_tracked_universities, ...                 │
│ - RLS gates internal-only access via fn_is_app_user()          │
│ - Edge Functions: signed-PDF URL, push delivery, change-notif  │
└────────────────▲───────────────────────────────────────────────┘
                 │ asyncpg (Postgres pooler, ap-northeast-2)
                 │ + Supabase service-role REST
┌────────────────┴───────────────────────────────────────────────┐
│ Python service  (services/uni_db/, 244 tests passing)          │
│ - Discovery: crawl ac.kr boards via per-source adapters        │
│ - Parse:     PyMuPDF text layer or EasyOCR fallback            │
│ - Extract:   8 archetype prompts → Anthropic Claude            │
│ - Validate:  difficulty-aware HITL gate                        │
│ - Translate: ko → en/uz/ru/vi via Papago/Claude with QC        │
│ - Now running on Hetzner CX23 (178.105.96.155, Falkenstein)    │
└────────────────────────────────────────────────────────────────┘
```

## 3. Phase history (one-line each)

- **Phase 0** (`README.md`) — Scaffolded. Everything against fixtures, no live calls.
- **Phase 1** (`PHASE_1_NOTES.md`) — Multi-signal archetype classifier, production prompts, Korean date/number parsers, HITL queue views, Flutter widget surfaces.
- **Phase 2** (`PHASE_2_NOTES.md`) — EasyOCR over Naver Clova (ADR-002), internal-only RLS (ADR-007), proposed_sources HITL flow, top-30 source registry seed, Supabase Storage (ADR-009).
- **Phase 3** (`PHASE_3_DESIGN.md`) — English translation default-on, Edge Functions, push tokens, /admin/review and /institutions/compare Flutter routes, real prod-schema baseline.

All four phases are **implemented in code and applied to production**. ADR set is in `docs/decisions/` (001–010 + amendments).

## 4. Current production DB state (as of 2026-05-14 06:50 UTC)

Connected via the new pooler URL (see `services/uni_db/.env`):

| Table | Row count |
|---|---|
| `institutions` | 0 |
| `recruitment_units` | 0 |
| `announcement_sources` | 34 (4 `live`, 30 `discovered`) |
| `review_queue` | 0 |
| `announcements` | 0 |

Live sources promoted in the prior session (status flipped from `discovered` to `live`):

- `https://admission.snu.ac.kr/international/notice` (Seoul National)
- `https://admission.yonsei.ac.kr/`
- `https://admission.yonsei.ac.kr/mirae`
- `https://oku.korea.ac.kr/oku/cms/FR_CON/index.do?MENU_ID=700` (Korea Univ.)

The rest of the 30 `discovered` sources are awaiting promotion (they're top-30 KR admission boards per the audit's §1.2 priority list — Konkuk, Hongik, Dongguk, Inha, Sookmyung, UNIST, GIST, DGIST, Chonnam, etc.). Promote them via SQL `UPDATE` once their selectors are written, or use the `proposed_sources` HITL flow.

## 5. Recent commit history (last session)

Branch `claude/store-readiness-p0-p1` on the main repo, all from the UI/UX audit work:

```
0f992d3 fix(android): bump Kotlin language/api version floor to 1.9 universally
d27dc29 fix(android): normalize JVM target to 17 for legacy plugins
aa1f81a fix(android): dispatch namespace shim dynamically
57165d1 fix(ui): give play/pause IconButton a defined hit region
d20d3f9 fix(ui): add errorBuilder/loadingBuilder to Image.network sites
3849e83 chore(ui): remove dead AdaptiveTextField widget
0b47a80 fix(a11y): bump body text from Colors.white38 to white70
805d212 chore(format): apply dart format across lib/
38523fa chore(ui): migrate withOpacity -> withValues(alpha:)
4b6b998 refactor(nav): swap BottomNavigationBar (M2) for AdaptiveBottomNavigation (M3)
c502c3a feat(i18n): localize a11y tooltip strings
38471ff fix(a11y): add semantic labels to icon controls
4a66baf fix(a11y): add autofill hints + AutofillGroup on auth forms
bd7fb03 fix(a11y): add tooltips to icon buttons
012d94b feat(i18n): localize training + drafting workspace
5bbc44d feat(i18n): localize account + auth flow screens
0ac1221 fix(android): inject namespace for AGP-8-incompatible plugins
fc15ee6 feat(i18n): localize bottom nav + tab AppBars + nav titles
8d56d59 fix(training): make ghost-text accept tap-able on mobile
bd1dcf1 fix(account): wire AccountScreen into router
```

**Working tree has uncommitted changes** in `lib/l10n/app_localizations*.dart` (regenerated by some `dart format`/sync pass) plus untracked APKs and audit doc. Those are unrelated to uni_db; leave them or commit on a separate branch.

The CRM (`hanguk-uz-claude` at `C:\Users\User\Desktop\hanguk-uz-claude`) has the Phase 3R-A reviewer queue and 3R-B cutover both **merged into `main`** as commit `0d239fa` (PR #1). Vercel auto-deploys.

## 6. Hetzner worker host — full details

**This is where the production Python worker runs.** Provisioned 2026-05-14 by the prior session via the Hetzner Cloud API.

| | |
|---|---|
| Server name | `hanguk-uni-db-worker` |
| Server ID | `130919174` |
| Public IPv4 | `178.105.96.155` |
| Public IPv6 | `2a01:4f8:c010:9441::/64` |
| Type | `cx23` (2 vCPU, 4 GB RAM, 40 GB disk, x86_64) |
| Location | `fsn1` — Falkenstein, Germany |
| Image | Ubuntu 24.04.4 LTS |
| Cost | €4.99/mo (€0.007/hr) |
| SSH user | `root` |
| SSH key | `C:\Users\User\.ssh\hanguk_hetzner` (private) + `.pub` (public) |
| Project install path | `/opt/hanguk-uni-db/uni_db/` |
| Project venv | `/opt/hanguk-uni-db/uni_db/.venv/` (Python 3.12.3) |
| Project .env | `/opt/hanguk-uni-db/uni_db/.env` (mode 0600, root only) |

### 6.1. How to SSH into the worker host (Windows OpenSSH is broken)

Run from `C:\Users\User\Desktop\Hanguk\services\uni_db\.venv\Scripts\python.exe`:

```python
import paramiko
from pathlib import Path

key = paramiko.Ed25519Key.from_private_key_file(str(Path.home() / ".ssh" / "hanguk_hetzner"))
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(hostname="178.105.96.155", username="root", pkey=key, timeout=30)

stdin, stdout, stderr = ssh.exec_command("YOUR COMMAND")
print(stdout.read().decode())
ssh.close()
```

For interactive multi-command sessions, wrap `ssh.exec_command` in a helper:

```python
def run(cmd, *, timeout=120):
    _, out, err = ssh.exec_command(cmd, timeout=timeout)
    rc = out.channel.recv_exit_status()
    return rc, out.read().decode(errors="replace"), err.read().decode(errors="replace")
```

For file upload, use `ssh.open_sftp()` and `sftp.put(local, remote)` or `sftp.open(remote, 'wb').write(bytes)`. The prior session used in-memory `tarfile` + sftp upload to deploy the project — see git history if you want the exact pattern.

### 6.2. What's already installed on the server

- Ubuntu 24.04, Python 3.12.3
- `apt`: `python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev poppler-utils libpq-dev git rsync`
- venv at `/opt/hanguk-uni-db/uni_db/.venv/`
- All Python deps from `pyproject.toml`'s `[dev]` extra: `anthropic 0.102.0`, `supabase`, `asyncpg`, `pymupdf`, `httpx`, `beautifulsoup4`, `lxml`, `pytest` ...
- **NOT installed:** the `heavy` extras (EasyOCR + torch, ~2 GB). Install with `.venv/bin/pip install -e '.[heavy]'` when the parse worker needs OCR. PyMuPDF text-layer extraction works without it for most PDFs.
- All 244 tests pass on the server (`.venv/bin/python -m pytest -q --tb=no` → `244 passed in 1.71s`)

### 6.3. Verified external connectivity from the server

| To | Latency | Status |
|---|---|---|
| Supabase pooler (Seoul `aws-1-ap-northeast-2`) | ~250 ms | ✅ Postgres 17.6 |
| Anthropic API | ~50 ms | ✅ Haiku replies |
| SNU admissions board (`admission.snu.ac.kr`) | ~250 ms | ✅ 200, 107 KB, Korean |
| Yonsei admissions board (`admission.yonsei.ac.kr`) | ~250 ms | ✅ 200 |

### 6.4. What's NOT yet set up on the server

- No systemd unit. Workers don't run automatically.
- No cron / systemd timer. No scheduled discovery polling.
- No log rotation config.
- No firewall lockdown (Hetzner Cloud Firewall not configured; default OS firewall is permissive).
- No automatic security updates configured (Ubuntu unattended-upgrades not explicitly enabled).
- No HITL reviewer onboarded.

## 7. File map — where everything lives

### Local laptop

```
C:\Users\User\Desktop\Hanguk\           # main Flutter + Supabase repo
├── lib/features/uni_db/                # 25 Dart files — Flutter UI
├── supabase/migrations/                # 38 uni_db migrations (all applied to prod)
├── services/uni_db/                    # Python service (uploaded to Hetzner)
│   ├── pyproject.toml
│   ├── README.md
│   ├── PHASE_1_NOTES.md
│   ├── PHASE_2_NOTES.md
│   ├── PHASE_3_DESIGN.md
│   ├── TRANSLATION_GLOSSARY.md
│   ├── .env                            # ⚠️ secrets — gitignored
│   ├── .env.example
│   ├── src/uni_db/
│   │   ├── config.py
│   │   ├── cli.py
│   │   ├── discovery/
│   │   │   ├── adapters/html_list_adapter.py    # generic
│   │   │   ├── adapters/naver_search_adapter.py
│   │   │   ├── adapters/rss_adapter.py
│   │   │   └── classifier.py, change_detection.py, registry.py
│   │   ├── parse/                      # pdf_text, ocr_easyocr, sections, tables, dates_ko, numbers_ko
│   │   ├── extract/                    # archetype dispatcher, prompts/, llm_anthropic, validators
│   │   ├── translate/                  # papago, deepl, claude, back_translation_qc, glossary, pipeline
│   │   ├── workers/                    # discovery_worker, parse_worker, translate_worker
│   │   ├── hitl/digest.py
│   │   └── storage/                    # supabase_storage (canonical), r2 (deprecated)
│   ├── tests/
│   │   ├── unit/                       # 200+ unit tests
│   │   └── integration/                # 8 integration tests
│   └── .venv/                          # Windows venv (paramiko + anthropic, 244 tests pass)
├── docs/audits/                        # store-readiness, ui_ux, kakaotalk, map audits
├── docs/decisions/                     # 10 ADRs (001–010 + amendments)
└── handoff/                            # prior + this handoff
    └── 2026-05-14-uni-db-next-session/ # ← you are here
```

### Hetzner server

```
/opt/hanguk-uni-db/uni_db/              # exact copy of services/uni_db/ from laptop
├── src/uni_db/
├── tests/
├── .env                                # mode 0600, root only — secrets live here
├── .env.example
└── .venv/                              # Linux venv, Python 3.12.3, all deps installed
```

## 8. The Python service CLI

`uni-db --help`:

```
review-digest       Print HITL queue as markdown
crawl   --source X  Run discovery against a source (fixture mode only via CLI)
parse   --fixture   Run extraction over a fixture PDF
schema-check        Lint the migrations directory
```

**Important:** the `crawl` CLI subcommand only reads fixtures (`tests/fixtures/<name>.html`). For real live crawls, invoke `workers.discovery_worker.run_one_source()` programmatically with an adapter+selectors. There is no production CLI for live crawl yet — you need to write the orchestration script. See `NEXT_STEPS.md`.

## 9. Sample/fixture references that are useful for selector writing

The repo already has hand-curated example documents per archetype:

```
docs/samples/archetype-A-snu.md
docs/samples/archetype-B-korea-univ.md
docs/samples/archetype-B-yonsei.md
docs/samples/archetype-C-knu.md
docs/samples/archetype-C-pnu.md
docs/samples/archetype-D-dongguk.md
docs/samples/archetype-D-sogang.md
docs/samples/archetype-E-ewha.md
docs/samples/archetype-F-knua.md
docs/samples/archetype-G-kaist.md
docs/samples/archetype-G-unist.md
docs/samples/archetype-H-inha-tech.md
```

Plus `services/uni_db/tests/fixtures/snu_list.html` is a real-shape (sanitized) SNU listing for the `HtmlListAdapter` to test against.

## 10. ADR-driven decisions you should know about

(All under `docs/decisions/` — read those for full reasoning.)

| ADR | Decision | Operational impact |
|---|---|---|
| 001 | Budget ceiling ~€80/mo realistic, €960/mo high-season cap | Anthropic billing alerts should be set |
| 002 | EasyOCR over Naver Clova for OCR | Pulls ~2 GB torch when installed (`.[heavy]`) |
| 003 | Hetzner CX22 (now CX23) over serverless | Server is now provisioned ✅ |
| 004 | Uzbek translation default-on (was: default-off + reviewer-gated) | `UNI_DB_TRANSLATION_LANGUAGES=en,uz` |
| 005 | In-office HITL reviewer (deferred, none hired) | review_queue rows accumulate but no human acts on them yet |
| 007 | Internal-only — no public API, RLS via `fn_is_app_user()` | App users must be authenticated to read uni_db tables |
| 009 | Supabase Storage over Cloudflare R2 | Bucket created in migration `20260606000000` |

## 11. Useful SQL patterns for the prior agent's playbook

```sql
-- See per-status source counts:
select status, count(*) from public.announcement_sources group by 1 order by 2 desc;

-- Promote a source from discovered → live:
update public.announcement_sources set status = 'live' where url_ko = '<URL>';

-- See the HITL review queue:
select * from public.v_review_queue_dashboard limit 25;

-- See institutions with at least one recruitment unit (the user-facing data):
select i.id, i.name_ko, count(ru.id) as units
  from public.institutions i
  left join public.recruitment_units ru on ru.institution_id = i.id
 group by i.id, i.name_ko order by units desc;
```

## 12. Things the previous agent learned the hard way

- **`subprocess.run(['ssh', ...])` and shell `ssh` don't work** in Cowork-mode PowerShell. Exit 255 with no output. Use paramiko.
- **`Get-Content` on `.env` files** can include the inline comments (`UNI_DB_LIVE_APIS=true  # comment`), but the `uni_db.config.settings` loader strips them correctly. Don't try to "clean" them in PowerShell.
- **PowerShell's `Set-Content -NoNewline`** can collapse line breaks. When editing `.env`, use `@"..."@` here-strings + `-Encoding ASCII` to keep separate lines.
- **Hetzner CX22 is deprecated.** CX23 is the same shape — 2 vCPU / 4 GB / 40 GB at €4.99/mo.
- **`db.<ref>.supabase.co` only resolves on IPv6.** Use the pooler URL (`aws-1-ap-northeast-2.pooler.supabase.com`) for asyncpg from IPv4-only hosts.
- **The Supabase Connect modal shows `[YOUR-PASSWORD]` literally** — never substituted. You either remember the password or reset it. The current password is in `.env`.

---

End of HANDOFF.md. Read `CREDENTIALS_REFERENCE.md` and `NEXT_STEPS.md` next.
