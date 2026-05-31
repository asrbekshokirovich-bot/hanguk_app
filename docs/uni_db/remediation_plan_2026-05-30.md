# Post-audit remediation plan — 2026-05-30

_Audit run 4 days after PR #36 merged (the staleness/translation/ingest guards).
Confirms the merged code behaved exactly as designed; this plan clears the
remaining items the audit surfaced. Owner-reference doc._

## Audit snapshot (2026-05-30, from `v_uni_db_health` + queries)

- **Publish ran on merge day, 8 approved items:** 3 published (cju req, hanseo req,
  gimcheon sch — all undated/current), **5 held as stale** (cdu 2017, gnu/knsu/
  hanyang 2022, hanseo-sch 2025). The hold guard prevented a 2017 guidebook from
  publishing as 2027 — exactly its purpose.
- **Translations: 322 rows, 0 garbage** (0 placeholder residue / reasoning leaks /
  Korean echoes / disabled-lang). The suspect-guard holds.
- **Discovery/ingest active:** 107 live sources, 62 documents (46 parsed),
  extraction 83.5% (30d), **71 new open review items across 26 universities**.
- **Institutions:** all placeholder names backfilled (KO+EN), still hidden from map.

## The 6 tracks

| Track | Item | Owner | Status |
|---|---|---|---|
| **A — unblock data** | A1 approve 3 pending 2026 sources (hanseo, knsu) | operator→**me** | ✅ done (promoted live) |
| | A2 re-approve genuine rejected 2026 guides (hanyang Seoul + ERICA) | operator→**me** | ✅ done; 3 grad guides left rejected |
| | A3 run **uni-db discover (targeted)** for cdu + gnu (no 모집요강 found) | **operator** | ⏳ GitHub Actions button |
| | A5 confirm year on 3 unverified cycles | operator | ⚠️ needs the source PDF; left unverified (correct). Re-ingest replaces them |
| **B — observability** | `published_outcome` column + honest `v_uni_db_health` (published/held split) + `cycles_unverified` | **me** | ✅ shipped (migration + view) |
| | `uni-db publish --force <id>` operator override for a held item | **me** | ✅ shipped |
| **C — security** | Revoke anon EXECUTE on uni_db `SECURITY DEFINER` fns; set `search_path` | **me** | ▶ in progress |
| | Enable Auth leaked-password protection | operator | ⏳ dashboard toggle |
| **D — frontend (hanguk.uz)** | content viewer, PDF popup fix, trust signals, **held/unverified badges**, filters, `empty_extraction` reason, **"mark current & publish"** action (calls `--force`) | frontend | ⏳ prompt handed off |
| **E — sustainability** | freshness alert (held>10 for >7d), golden eval set, HWP/OCR, operator runbook | me | backlog |
| **F — docs** | this plan + perfection_plan progress | me | ✅ |

## What needs a human (only these)

1. **A3** — Actions → **uni-db discover** → mode **targeted** → Run (covers cdu + gnu).
2. **A4** — work the 71-item review backlog (Korea Univ alone has 10 sections).
3. **C/Auth** — toggle leaked-password protection in the Supabase dashboard.
4. Eyeball the 22 backfilled institution names, then reveal on the map.

## Operator override cheatsheet

A held item you've confirmed is current (after checking its source PDF):

```
uni-db publish --force <review_queue_id>
```

Bypasses the past-cycle staleness hold for that one item and publishes it.
