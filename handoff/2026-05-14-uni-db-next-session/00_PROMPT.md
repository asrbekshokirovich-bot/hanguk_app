# Hand-off prompt — Hanguk university database (uni_db)

> **Copy everything from `---` below into a fresh agent session. Nothing above the line is for the agent.**

---

You are picking up the Korean University Database (`uni_db`) work for the Hanguk Flutter app at `C:\Users\User\Desktop\Hanguk`. The infrastructure is **fully built, deployed, and tested end-to-end**. What's still missing is **operational** — per-university CSS selectors for the discovery adapter, and a systemd/cron scheduler on the worker host. The user wants to finish enough that real Korean university data starts flowing into the production Supabase database.

**Before doing anything else, read these three files in order** (they are next to this prompt on disk):

1. `C:\Users\User\Desktop\Hanguk\handoff\2026-05-14-uni-db-next-session\HANDOFF.md`
   — Full project context: architecture, phase history, current DB state, what got done in the prior session, file map.
2. `C:\Users\User\Desktop\Hanguk\handoff\2026-05-14-uni-db-next-session\CREDENTIALS_REFERENCE.md`
   — Where every credential is stored (file paths only — actual secret values are in `services/uni_db/.env`). Security notes about what was leaked in chat last session.
3. `C:\Users\User\Desktop\Hanguk\handoff\2026-05-14-uni-db-next-session\NEXT_STEPS.md`
   — Prioritized work list with concrete starting commands.

After reading those, **report back to the user with a 5-line "I'm caught up" summary** confirming you read everything, then ask them which of the three priorities they want to start with. Do NOT silently start working without that check-in — the user has been through a lot of provisioning friction and wants confirmation you're aligned.

**Critical caveats to memorize before any tool use:**

- **Windows OpenSSH (`ssh`, `ssh-keygen`) is broken in this PowerShell context** — exits 255 with zero stderr output. Use Python's `paramiko` library (already installed in the laptop venv at `C:\Users\User\Desktop\Hanguk\services\uni_db\.venv\`) for any SSH or key-generation work. There is example code in `HANDOFF.md` § "How to SSH into the worker host".
- **Hetzner's web Console is gated by Heray Proof-of-Work** which detects Chrome DevTools Protocol attachment and refuses to release the redirect. Do NOT try to drive the Hetzner UI via Chrome MCP or computer-use. For anything Hetzner-related, use the Cloud API directly with `httpx` and the API token (or ask the user to act in their normal Chrome window).
- **Anti-bot bypass is a hard safety rule** — never try to defeat CAPTCHA / fingerprinting / POW challenges. If you hit one, escalate to the user.
- **Several secrets were shared in chat history last session** — Anthropic API key, Supabase database password (`qMjuqk6eTO4Oucp6`), Hetzner Cloud API token. The user was told to rotate them. Don't echo them back in your replies. They live in `services/uni_db/.env` on both laptop and the Hetzner server (which is the source of truth; read from there).
- **The Hetzner API token is the only one that may already be revoked.** If your work needs to make new servers / change networking, ask the user for a fresh token rather than assuming the old one still works.
- **The Hanguk Supabase project is `lysjdtyanhdfphqyijsr`** (named "Hanguk 2026", in `asrbekshokirovich-bot's Org` on Hetzner — sorry, on Supabase). There is a similarly-named but unrelated `ybtfepdqzbgmtlsiisvp` that the user briefly went to by mistake; **always confirm you're acting on `lysj...` before any DB / API change**.

**What success looks like for this session:**

The user can install the latest Hanguk APK on their phone and see at least one real (not demo-seeded) Korean university announcement / deadline / requirement row that was crawled, extracted, and translated by the system end-to-end since this session began.

To get there, the minimum-viable plan is:
1. Write `HtmlListSelectors` for one university (SNU is easiest — `tests/fixtures/snu_list.html` already exists as a reference fixture). Save under `src/uni_db/discovery/adapters/configs/` (new directory) as `snu.py`.
2. Write a tiny orchestration script that loads the live source rows from `announcement_sources`, picks the right adapter+selectors per source, calls `run_one_source`, and writes findings to `crawl_runs` + `announcements`.
3. Run the script ONCE manually (from the Hetzner server) against the SNU source. Verify at least one announcement lands in the DB.
4. If a PDF attachment was discovered: run the parse worker on it with `UNI_DB_LIVE_APIS=true` and the live Anthropic key. Verify structured extraction lands in `recruitment_units` (or `review_queue` if validators flag it for HITL).
5. Wire systemd + a timer to run the orchestration script every 10 min on the Hetzner server. Polish.

You can also propose alternative plans if you think there's a faster path to "real data visible in the app." The user is responsive and decisive; check with them before changing plans.

**A few useful one-liners** (the next agent will likely run these):

```powershell
# Open the laptop venv (Python 3.13 is system; project venv has the right libs):
cd C:\Users\User\Desktop\Hanguk\services\uni_db
.\.venv\Scripts\python.exe -m pytest -q --tb=no   # expect 244 passed in ~8s

# SSH into the Hetzner worker (use paramiko in Python — NOT the windows ssh binary):
# Server: hanguk-uni-db-worker | 178.105.96.155 | Ubuntu 24.04 | /opt/hanguk-uni-db/uni_db/
# Private key: C:\Users\User\.ssh\hanguk_hetzner
# Example connect snippet is in HANDOFF.md § "How to SSH into the worker host"

# Read the current DB state (live sources, table counts):
cd C:\Users\User\Desktop\Hanguk\services\uni_db
.\.venv\Scripts\python.exe -c "import asyncio, asyncpg; from uni_db.config import settings; print(asyncio.run(asyncpg.connect(settings.supabase_db_url)))"
```

When the user replies with their priority pick, start work. Use `Plan` agent if you need to scope per-university selectors, use `general-purpose` if you need broad investigation, otherwise act directly with PowerShell + paramiko + Python. Keep TodoWrite updated.
