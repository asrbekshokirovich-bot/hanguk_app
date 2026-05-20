# Next Steps — prioritized work for this session

**Goal of the session:** end with at least one **real** Korean university announcement / deadline / requirement row visible in the Hanguk APK — crawled, extracted, and stored on the production Supabase by the system itself.

There are three concrete priorities, in order. **Pick one with the user before starting** — don't silently choose.

---

## Priority 1 (recommended) — End-to-end "one real PDF" walk

The fastest path to "real data in the app." Skip the cron loop for now; do everything once by hand to prove the pipeline works against a live Korean source. Then automate.

### Sub-tasks

1. **Write CSS selectors for Seoul National (SNU).** Easiest archetype — there's already a fixture (`services/uni_db/tests/fixtures/snu_list.html`) and a sample doc (`docs/samples/archetype-A-snu.md`). Steps:
   - Read `services/uni_db/src/uni_db/discovery/adapters/html_list_adapter.py` to understand the `HtmlListSelectors` dataclass.
   - From the laptop, fetch `https://admission.snu.ac.kr/international/notice` with httpx (works — verified). Inspect the HTML for the announcement-row selector.
   - Write `services/uni_db/src/uni_db/discovery/adapters/configs/snu.py` exporting an `HtmlListSelectors` instance.
   - Optionally add a parallel test fixture to `tests/fixtures/` if SNU's HTML has changed since the existing fixture.
2. **Write a tiny orchestration script** (`services/uni_db/scripts/run_discovery_once.py`) that:
   - Connects to the DB (asyncpg, `settings.supabase_db_url`).
   - Loads `live` rows from `announcement_sources`.
   - For each, picks the right adapter + selector config (start with just SNU).
   - Calls `workers.discovery_worker.run_one_source()` with an httpx client.
   - Writes the resulting `DiscoveryRun.findings` to `announcements` + `crawl_runs`.
   - Reschedules via `discovery.registry.reschedule()`.
3. **Upload `snu.py` + the script to the Hetzner server** via paramiko SFTP. Run it manually:
   ```
   cd /opt/hanguk-uni-db/uni_db
   .venv/bin/python scripts/run_discovery_once.py --source-url 'https://admission.snu.ac.kr/international/notice'
   ```
   Expect 0–10 new announcement rows depending on what SNU has posted recently.
4. **If at least one announcement has a PDF attachment:** run the parse worker on it:
   ```
   .venv/bin/python -m uni_db.workers.parse_worker --announcement-id <uuid>
   ```
   (Or whatever the actual invocation is — read `parse_worker.py` to confirm. May need a small wrapper script.)
   This will call live Anthropic Claude (~$0.30–$1.30 per guideline). Validate that structured fields land in `recruitment_units` or `review_queue`.
5. **Verify in the Flutter app** by reading from the DB:
   ```sql
   select * from public.announcements order by posted_at desc limit 5;
   select * from public.recruitment_units order by created_at desc limit 5;
   ```
   The Flutter `VerifiedDeadlineCard` should pick up rows in `v_user_upcoming_deadlines` once a tracked user exists.

### What "success" looks like

User opens the Hanguk APK → goes to Applications tab → sees at least one real upcoming Korean deadline rendered (not a demo seed). Or admin opens `/admin/review` in the CRM → sees real `review_queue` entries.

---

## Priority 2 — Production scheduling (systemd + cron)

If the user wants "set it and forget it" before any data is actually flowing.

### Sub-tasks

1. **Write a systemd service unit** for the discovery loop:
   ```
   /etc/systemd/system/hanguk-uni-db-worker.service
   ```
   - User: `root` (or create a `unidb` user)
   - WorkingDirectory: `/opt/hanguk-uni-db/uni_db`
   - ExecStart: `.venv/bin/python -m uni_db.workers.discovery_worker --continuous`
   - Restart: `on-failure`
   - StandardOutput: `journal`
   - EnvironmentFile: `/opt/hanguk-uni-db/uni_db/.env`
2. **Write a systemd timer** for periodic invocation (or use the worker's own internal cron loop — check `discovery_worker.py` for the existing pattern).
3. **OR use Supabase pg_cron** instead of OS-level cron (plan §E.4 — the original intent). Requires `pg_cron` extension on Supabase, which may or may not be enabled. Check via `select extname from pg_extension`.
4. **Set up log rotation** (`/etc/logrotate.d/hanguk-uni-db`).
5. **Set up Hetzner Cloud Firewall** restricting inbound to SSH only.
6. **Enable Ubuntu unattended-upgrades** for security patches.

### What "success" looks like

`systemctl status hanguk-uni-db-worker` shows `active (running)`. `journalctl -u hanguk-uni-db-worker -n 50` shows recent activity. The user can power off their laptop and the workers keep running.

---

## Priority 3 — Selector backlog (the marathon)

Per-university CSS selectors for the remaining 30 sources. Each takes 1–2 hours of HTML inspection. Order by audit §1.2 priority:

1. Seoul National (SNU) — covered by Priority 1
2. Yonsei
3. Korea University
4. KAIST
5. POSTECH (not in seed yet — may need to add)
6. SungKyunKwan
7. Hanyang
8. ... (see `supabase/migrations/20260606000300_uni_db_v2_seed_announcement_sources_top30.sql` for the full list)

This is grindwork. Don't do all 30 in one session — pace it. Suggested: knock out the top 5 and ship; do the rest in subsequent sessions or hand to a contracted-out HTML inspector.

---

## Don't do (yet)

- Hire a HITL reviewer (ADR-005, deferred — user said no this session).
- Hire a native Uzbek translation reviewer (ADR-004 amend 2, deferred — user said no).
- Switch from Supabase Storage to R2 (ADR-009 made Supabase canonical, R2 deprecated).
- Bypass the bot challenge on Hetzner Console — always escalate.
- Save any secrets to memory (per system rules).

---

## Quick verification commands (for after any work)

```powershell
# Run the laptop test suite (should still be 244 passing):
cd C:\Users\User\Desktop\Hanguk\services\uni_db
.\.venv\Scripts\python.exe -m pytest -q --tb=no

# Snapshot the DB state:
.\.venv\Scripts\python.exe -c "
import asyncio, asyncpg
from uni_db.config import settings
async def m():
    c = await asyncpg.connect(settings.supabase_db_url)
    for t in ['institutions', 'announcement_sources', 'announcements', 'recruitment_units', 'review_queue']:
        n = await c.fetchval(f'select count(*) from public.{t}')
        print(f'{t}: {n}')
    await c.close()
asyncio.run(m())
"
```

```python
# Snapshot the Hetzner server state (paste into a Python script run via the laptop venv):
import paramiko; from pathlib import Path
key = paramiko.Ed25519Key.from_private_key_file(str(Path.home() / '.ssh' / 'hanguk_hetzner'))
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('178.105.96.155', username='root', pkey=key, timeout=30)
for cmd in [
    "uptime",
    "df -h / | tail -1",
    "free -h | head -2",
    "ls /opt/hanguk-uni-db/uni_db/",
    "/opt/hanguk-uni-db/uni_db/.venv/bin/python -m pytest -q --tb=no 2>&1 | tail -2",
]:
    _, out, _ = ssh.exec_command(cmd)
    print(f'$ {cmd}\n  {out.read().decode().strip()}')
ssh.close()
```

---

End of NEXT_STEPS.md.
