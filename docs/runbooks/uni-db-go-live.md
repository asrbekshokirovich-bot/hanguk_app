# Go live: sync all universities and keep it running

Plain, step-by-step instructions to (A) catch up the backlog so **all
universities** appear for staff, and (B) turn on **automatic** syncing so it
stays fresh on its own.

> Background: today the robot only has data for 2 universities because the
> fetch+read stage was run by hand a few times and nothing runs it on a
> schedule. See [`docs/uni_db/pipeline_coverage_audit_2026-05-24.md`](../uni_db/pipeline_coverage_audit_2026-05-24.md).

You need three secrets before starting (from
[`docs/credentials.md`](../credentials.md)):

| Secret | What it's for |
|---|---|
| `SUPABASE_DB_URL` | the production database connection string |
| `SUPABASE_SERVICE_ROLE_KEY` (+ `SUPABASE_URL`) | uploading the downloaded PDFs to storage |
| `ANTHROPIC_API_KEY` | the AI that reads the PDFs (this is the paid part) |

Money note: reading PDFs uses the paid AI. A full run of ~12 universities is
a few US dollars, one time. Ongoing hourly runs are cheap because each run
only re-checks universities that are "due".

---

## Part A — one-time catch-up (see all universities today)

This runs the whole pipeline once, from any computer that has the repo and
the three secrets (your laptop is fine). It does **not** need the server.

1. **Get the code and a Python environment.**
   ```bash
   cd services/uni_db
   python3.12 -m venv .venv
   .venv/bin/pip install -e ".[heavy]"
   ```

2. **Add the secrets.** Copy the template and edit it:
   ```bash
   cp .env.example .env
   ```
   In `.env`, set these (leave the rest as-is):
   ```
   UNI_DB_LIVE_APIS=true
   UNI_DB_LIVE_CRAWL=true
   SUPABASE_DB_URL=postgresql://postgres:...        # from docs/credentials.md
   SUPABASE_URL=https://lysjdtyanhdfphqyijsr.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=...                     # from docs/credentials.md
   ANTHROPIC_API_KEY=...                             # from docs/credentials.md
   ```

3. **Run the three stages** (each line prints a summary when it finishes):
   ```bash
   # 1) visit each university site and list the posts (re-labels them too)
   .venv/bin/python scripts/run_discovery_once.py --since 30

   # 2) download the admission guide PDFs and read them  <-- the paid AI step
   .venv/bin/uni-db run-pipeline --limit 100

   # 3) translate the results for the review screen
   .venv/bin/python scripts/run_translate_once.py --limit 200
   ```

4. **Check it worked.** Either open the staff review site, or run:
   ```bash
   .venv/bin/uni-db review-digest
   ```
   You should now see items for many universities, not just Inha + KAIST.

If a university still shows nothing, it usually means its guideline PDF
genuinely isn't published yet, or its page needs a small adapter tweak —
note which ones and we can look.

---

## Part B — turn on automatic syncing (the permanent fix)

This puts the robot on a small always-on server (Hetzner, already decided in
[ADR-003](../decisions/003-worker-placement.md)) so it runs **every hour by
itself** — forever. The server's very first run also does the catch-up, so
if you do Part B you can skip Part A.

1. **Create the server.** Follow
   [`hetzner-provisioning.md`](./hetzner-provisioning.md) sections 1-5
   (create the CX22 box, run `infra/bootstrap.sh`). This produces a server
   with the `uni-db` user and the `/opt/uni_db` layout.

2. **Put the secrets on the server.** Create `/etc/uni_db/env` from
   [`infra/env.example`](../../infra/env.example) and fill in the same values
   as Part A step 2 — and make sure:
   ```
   UNI_DB_LIVE_APIS=true
   UNI_DB_LIVE_CRAWL=true      # <-- must be true, the template ships it false
   ```
   ```bash
   # on the server, as root:
   install -o root -g uni-db -m 640 /dev/stdin /etc/uni_db/env < your-filled-env
   ```

3. **Deploy.** From your laptop (repo root):
   ```bash
   infra/deploy.sh <server-ip>
   ```
   This copies the code, installs dependencies, **enables the hourly sync
   timer**, and **runs one cycle immediately** (that first cycle is your
   catch-up).

4. **Confirm it's scheduled and running:**
   ```bash
   ssh root@<server-ip> 'systemctl list-timers uni-db-*'        # shows next run time
   ssh root@<server-ip> 'journalctl -u uni-db-sync -n 50'       # shows the last cycle
   ```
   `uni-db-sync` runs discovery → fetch+read → translate, every hour. During
   the summer off-season it mostly idles (the per-source schedule widens
   automatically); in admission season new guides appear within ~1 hour.

That's it — once Part B is done, the staff queue stays current on its own.

---

## Handy checks (read-only)

Count what's in the database right now (run in the Supabase SQL editor):
```sql
select count(*) filter (where guideline_document_id is not null) as fetched,
       count(*) as discovered
from public.announcements;

select i.name_en, count(g.id) as guides
from public.institutions i
left join public.guideline_documents g on g.institution_id = i.id
group by 1 order by guides desc;
```

## If something looks wrong

- **`run-pipeline` says it's refusing:** `UNI_DB_LIVE_CRAWL` and
  `UNI_DB_LIVE_APIS` must both be `true`, and `SUPABASE_DB_URL` must be set.
- **A stage failed but others ran:** that's by design (best-effort). Re-run
  the failed stage; check `journalctl -u uni-db-sync` for the reason.
- **Costs higher than expected:** lower `--limit` on `run-pipeline`, or check
  for a university re-fetching the same PDF (dedup is by file hash, so this
  is rare).
