# Cross-device continuation prompt

Paste the prompt block (between the `\`\`\``...`\`\`\`` markers in
"Step C" below) into a **fresh Claude Code chat on the new machine**,
**after** you've cloned the repo and created a working `.env`.

This prompt is for: same Claude account, **different physical device**
(could be Windows, macOS, or Linux — paths are normalised in the
prompt's instructions). Different machine means: no local repo, no
`.venv`, no `.env`, no clipboard with the data.go.kr key, no session
history from the old device.

---

## Pre-flight: things to do on the new device BEFORE pasting the prompt

### A. Install prerequisites
- **git** ≥ 2.40
- **Python 3.12+** (the repo's `pyproject.toml` requires `>=3.12`)
- (Optional but recommended) **Supabase CLI** for the migration workflow
- (Optional) **PowerShell 7+** if you're on Windows and want native
  scripts to "just work" (Windows PowerShell 5.1 also works)

### B. Clone + set up the working tree

```bash
# Pick a working directory you control. Examples:
#   Windows:   C:\Users\<you>\Desktop\Hanguk
#   macOS:     ~/Code/Hanguk
#   Linux:     ~/projects/Hanguk

git clone https://github.com/asrbekshokirovich-bot/hanguk_app.git Hanguk
cd Hanguk
git checkout claude/store-readiness-p0-p1
git pull   # ensure you have today's commits (CLAUDE.md, audit docs, etc.)
```

### C. Set up the `uni_db` Python service

```bash
cd services/uni_db

# Create a fresh venv (the laptop's .venv is NOT in git — must be rebuilt)
python -m venv .venv

# Activate (one of these depending on your OS):
#   Windows PowerShell:  .\.venv\Scripts\Activate.ps1
#   macOS / Linux bash:  source .venv/bin/activate

# Install the package + dev dependencies
pip install --upgrade pip
pip install -e ".[dev]"

# Sanity check
python -c "import uni_db; print('uni_db importable')"
pytest tests/unit -x -q           # should show 191 passed
```

### D. Populate `.env` (the trickiest cross-device step)

The `.env` file is gitignored — **none** of the secrets travelled with
the repo. You have two routes:

1. **Best — copy the file securely from the original device**
   - Use a password manager (1Password, Bitwarden, KeePassXC) to
     transfer the whole `.env` body.
   - Or use an end-to-end-encrypted file share (Magic Wormhole,
     Signal note-to-self, croc).
   - **Do NOT paste secrets into any chat (including this Claude
     chat), email, Slack, or unencrypted note.**

2. **Re-fetch each secret from its source**

   | Key | Where to re-fetch |
   |---|---|
   | `ANTHROPIC_API_KEY` | https://console.anthropic.com/ → Settings → API Keys → generate new (rotate the old one) |
   | `SUPABASE_URL` | Supabase dashboard → Project `lysjdtyanhdfphqyijsr` → Project Settings → API → Project URL |
   | `SUPABASE_ANON_KEY` | same → Project Settings → API → anon public key |
   | `SUPABASE_SERVICE_ROLE_KEY` | same → Project Settings → API → service_role secret (treat like a root password) |
   | `SUPABASE_DB_URL` | same → Database → Connection String → URI (with password) |
   | `DATA_GO_KR_APP_KEY` | https://www.data.go.kr/iim/api/selectApiKeyList.do (logged in as `hanguk1010`) |

   Then:
   ```bash
   cp .env.example .env
   # Edit .env and fill in the values above.
   ```

   Verify:
   ```bash
   .venv/bin/python -c "from uni_db.config import settings; \
     print('anth:', len(settings.anthropic_api_key), \
           'sb_db:', bool(settings.supabase_db_url), \
           'datagokr:', len(settings.data_go_kr_app_key))"
   # Expected: anth: 108  sb_db: True  datagokr: 64
   ```

### E. Verify connectivity (read-only, costs $0)

```bash
# data.go.kr live smoke (no Anthropic spend)
.venv/bin/python -c "
import asyncio, httpx
from uni_db.config import settings
async def main():
    url = 'https://apis.data.go.kr/B340014/BasicInformationService_1/getCodeByLargeSeries'
    async with httpx.AsyncClient() as c:
        r = await c.get(url, params={'serviceKey': settings.data_go_kr_app_key, 'pageNo':1, 'numOfRows':10, 'svyYr':2025})
        print('data.go.kr:', r.status_code, '00' in r.text and 'NORMAL SERVICE' in r.text)
asyncio.run(main())
"

# Supabase live smoke
.venv/bin/python -c "
import asyncio, asyncpg
from uni_db.config import settings
async def main():
    c = await asyncpg.connect(settings.supabase_db_url)
    n = await c.fetchval('select count(*) from public.adiga_calendar_events')
    print('staging adiga_calendar_events rows:', n)   # should be 27
    await c.close()
asyncio.run(main())
"
```

If both succeed, the new device is fully bootstrapped.

---

## Step 1 — Paste THIS prompt into a fresh Claude Code chat

(All inside the fenced block — copy everything between the fences.)

````
# Continuing the Hanguk uni_db project on a new device (handoff from 2026-05-17)

I've moved to a new machine. The repo is freshly cloned, the venv is built,
and `services/uni_db/.env` is populated. Same Claude account, same
GitHub account, same Supabase staging project (`lysjdtyanhdfphqyijsr`).

## Step 0 — Mandatory orientation reading (do this before any action)

Read these three files in order. They are your full context:

1. `<REPO_ROOT>/CLAUDE.md`
   — project memory: tech stack, layout, conventions, communication
   style, safety rules, glossary, common commands.
2. `<REPO_ROOT>/docs/audits/UNI_DB_STATUS_REPORT_2026-05-17.md`
   — six-phase status report. ~44% complete. Per-phase done /
   remaining / blocked.
3. `<REPO_ROOT>/docs/audits/UNIVERSITY_DB_CHANGE_AUDIT_2026-05-17.md`
   — full audit + 16 ranked recommendations.

(Substitute `<REPO_ROOT>` with the absolute path you just cloned the
repo into. Forward slashes on macOS/Linux; backslashes or forward
slashes on Windows — both work in PowerShell ≥ 6.)

## Step 1 — Confirm orientation (ONE short message)

Send me ONE short reply with:
- The branch you're on (should be `claude/store-readiness-p0-p1`)
- The 5 critical pending items from the status report's top
- The communication style I expect (short, /plan before non-trivial,
  AskUserQuestion for scope decisions, honest reporting, never
  auto-commit, surface cost projections before live LLM calls)

Do NOT summarise the audit. Just confirm orientation.

## Step 2 — Run the cross-device sanity checks (you may need to run them, not me)

If I haven't already, run these read-only checks and report results:

```bash
cd <REPO_ROOT>/services/uni_db

# 1) Unit tests should still pass on this machine
.venv/bin/python -m pytest tests/unit -x -q
# (Windows: .\.venv\Scripts\python.exe -m pytest tests/unit -x -q)
# Expected: 191 passed

# 2) Settings loaded correctly
.venv/bin/python -c "from uni_db.config import settings; print(\
  'anth len:', len(settings.anthropic_api_key),\
  'db_url set:', bool(settings.supabase_db_url),\
  'datagokr len:', len(settings.data_go_kr_app_key),\
  'live_apis:', settings.live_apis)"
# Expected: anth len: 108 / db_url set: True / datagokr len: 64 / live_apis: True

# 3) Staging DB connectivity + adiga backfill is intact
.venv/bin/python scripts/_verify_adiga_backfill.py
# Expected: 27 rows, mostly 정시 (13) + 수시 (14)
```

If any check fails, STOP and report. Don't push forward into broken
state.

## Step 3 — Pick a focus area

I want to drive one of these next. Recommend the highest-ROI option
unless I tell you otherwise:

A. **🟥 Rotate the leaked Gmail password** (transcript line 1 of
   `~/.claude/projects/C--Users-User-Desktop-Hanguk/3ae39a73-9651-43f6-8250-afdbd6619cff.jsonl`
   on the **previous** device — NOT this one). Security-critical.
   Walk me through; don't touch the file yourself.

B. **Install Adiga systemd timer on Hetzner.** Files committed at
   `infra/systemd/uni-db-adiga-calendar.{service,timer}`. Need one
   SSH session:
   ```bash
   sudo cp /opt/uni_db/infra/systemd/uni-db-adiga-calendar.* /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now uni-db-adiga-calendar.timer
   sudo systemctl start uni-db-adiga-calendar.service
   journalctl -u uni-db-adiga-calendar.service --since "5 min ago"
   ```
   I'll run; you tell me what success looks like.

C. **Apply for the 2 missing data.go.kr datasets** (모집요강 +
   교육부_고등교육기관). Both auto-approve through 활용신청. Last
   session's Gemini Antigravity prompt is at
   `docs/audits/ADIGA_URL_DISCOVERY_PROMPT.md` (different topic but
   same agent flow). Adapt or write a fresh prompt.

D. **Non-KAIST PDF download chain** (Phase 3, highest engineering ROI).
   Today only KAIST PDFs flow into `parse_worker`. 10 other
   universities need JS-mediated download follow-up. Worth a /plan
   because design varies per source. Probably touches
   `discovery/adapters/configs/` + `scripts/run_parse_once.py`.

E. **Provision production Supabase project.** `lysjdtyanhdfphqyijsr`
   is staging only. Phase 5 requires we make a prod project and
   replay every migration. Needs my input on cutover process.

F. **Counselor HITL UI** (Phase 6, Flutter side). `review_queue` rows
   accumulate but no admin dashboard exists. Foreign-student workflow
   needs counselor-in-the-loop for borderline extractions.

G. **Decide jovial-wiles worktree.** 22 uncommitted files implementing
   "drop Papago, Claude-only translation" parked on the previous
   device. Cannot inspect from this machine (worktree files are local
   only, not in git). Either I copy the patches to you, you re-do
   the work from scratch on this machine, or we discard.

H. **Something else** — tell me in my next message.

## Step 4 — When I pick

- For (A): walk me through; you don't have access to the previous
  device's transcript file, so I'll do the file edits.
- For (B), (C): walk me through; I run commands.
- For (D), (E), (F): use `/plan` first. Wait for explicit `proceed`.
- For (G): I'll either share the diff via paste or we'll discard.
- For (H): same defaults — short answers, `/plan` if non-trivial.

## Anti-patterns to avoid (carried over from the previous session)

- **Don't `git add -A`.** Working tree has APKs and `.env.bak` that
  must not enter history. Add by-name only.
- **Don't run scripts without UTF-8 stdout** on Windows. Korean text
  crashes cp1251 console. Use `$env:PYTHONIOENCODING = 'utf-8'` (PS)
  and `sys.stdout.reconfigure(encoding="utf-8", errors="replace")`
  inside the script.
- **Don't trust `os.environ`** for `.env` values. Pydantic-settings
  on Windows sometimes fails to load `.env` if a variable is pre-set
  empty in os.environ. Workaround:
  ```python
  from dotenv import load_dotenv
  from pathlib import Path
  load_dotenv(Path(__file__).resolve().parents[1] / ".env", override=True)
  ```
  at the top of any script that imports `uni_db.config`.
- **Don't claim success on 404s.** Verify with real GET (not HEAD —
  some Korean gov sites return 200-HTML for HEAD on missing files).
- **Don't ingest into prod-shaped tables without idempotency.** All
  upserts must use a natural-key `on conflict`.
- **Don't burn Anthropic tokens without a budget projection.**
  Per-field-group cache-hit ≈ $0.005. Full guideline (5 groups,
  no cache) ≈ $1.30. Surface expected cost before any live call.
- **Don't fabricate success.** If a step fails or returns ambiguous
  output, report the actual error. Previous sessions caught Gemini
  agents claiming success on resultCode=99 responses.

## Quick reference — state at start of this session

| Item | Value |
|---|---|
| Project root | `<REPO_ROOT>` (wherever you cloned) |
| Branch | `claude/store-readiness-p0-p1` (pushed to origin) |
| Staging Supabase | `lysjdtyanhdfphqyijsr.supabase.co` |
| Adapters live | 12 universities, ~97 announcements |
| Adiga calendar rows | 27 (cal year 2026) |
| Translations | 306 across 11 institutions, 4 languages (en/uz/vi/mn) |
| Field groups working | 5/5 (calendar, tuition, scholarships, documents_required, requirements) |
| Anthropic spend last session | $0.093 |
| Unit tests | 191/191 |
| Completion | ~44% by task count |

You're ready when:
- You've read CLAUDE.md + status report + audit
- The three sanity-check commands above all pass
- I've told you which focus area to start on

Don't begin work until all three conditions are met.
````

---

## Step 2 — Things I'd handle on the new device, not pass to Claude

These don't need to be in the prompt; they're your own checklist:

| Task | Why on you |
|---|---|
| 🟥 Rotate the leaked Gmail password (originally line 1 of transcript `3ae39a73-...jsonl` on the OLD device) | Security-critical and requires your password manager |
| Rotate the Anthropic API key | The audit flagged it as having appeared in chat history. Even if you didn't rotate yet, do it before the new device makes its first live call. Update `.env` after. |
| Rotate the Supabase DB password (`postgres.lysjdtyanhdfphqyijsr`) | Same reason. Update `SUPABASE_DB_URL` after. |
| Decide on Hetzner SSH key transfer | If you want to use option (B) on the new device, you need the SSH private key. Generate a new key on the new device + add it to `~/.ssh/authorized_keys` on Hetzner. **Don't** copy the old private key over. |
| GitHub CLI auth | `gh auth login` on the new device if you want to push from there |

## Step 3 — Pointers (also in CLAUDE.md, repeated here for the paste)

- Latest audit: `docs/audits/UNIVERSITY_DB_CHANGE_AUDIT_2026-05-17.md`
- Status report: `docs/audits/UNI_DB_STATUS_REPORT_2026-05-17.md`
- Task-status PDF: `docs/audits/UNI_DB_TASK_STATUS_2026-05-17.pdf`
- data.go.kr operational record: `docs/audits/DATA_GO_KR_ONBOARDING_REPORT.md` and `DATA_GO_KR_FOLLOWUP_2026-05-17.md`
- Adiga URL discovery prompt: `docs/audits/ADIGA_URL_DISCOVERY_PROMPT.md`
- Previous handoff package: `handoff/2026-05-14-uni-db-next-session/` (HANDOFF.md, NEXT_STEPS.md, 00_PROMPT.md, CREDENTIALS_REFERENCE.md)
- Build plan: `UNIVERSITY_DB_BUILD_PLAN.md`
- Original audit: `UNIVERSITY_DB_AUDIT.md`
- Current state: `CURRENT_STATUS.md`
- ADRs: `docs/decisions/`
- Hetzner runbook: `docs/runbooks/`
