# University DB — Status Report (2026-05-17)

**Where we are:** core pipeline works end-to-end on staging. 12 universities live, ~97 announcements, 306 translations, all 5 PDF-extraction field groups producing clean data. The system is **functionally complete in lab conditions**; the remaining work is *scale-out* (more universities, more languages) and *production hardening* (live deploy, monitoring, UI).

**Icons:** ✅ done · ⏳ in progress · 🔲 to do

---

## Phase 1 — Foundation (DB + Pipeline + Infra)

✅ Supabase schema for institutions, admission_cycles, cycle_dates, requirements, tuition, scholarships, documents_required, announcements, extraction_jobs, review_queue, translations
✅ Pipeline: discovery → parse (Claude) → translate → DB
✅ Hetzner VPS hosting + systemd timers (4 services: discovery, parse, ocr, translate)
✅ Adiga calendar table added (`adiga_calendar_events`, 27 rows on staging)
✅ RLS policies on all uni-db tables (tightened to `fn_is_app_user()` in v2)
🔲 Re-create missing `guideline-blobs` Supabase Storage bucket on staging
🔲 Provision a separate **production** Supabase project (staging is the only one set up)

---

## Phase 2 — Data Sources (Where the data comes from)

**Status:** 12 of ~330+ Korean four-year universities covered. ~3-4% breadth.

✅ **12 university adapters live:** SNU, KU, KAIST, Yonsei, Inha, Kangwon, Jeju, Hanyang, CBNU, JBNU, SKKU, Konkuk
✅ **data.go.kr** account + key + 4 KCUE datasets approved (basic info, dept codes, student status, financial)
✅ **Adiga (어디가)** scheduleAjax.do integration — 27 calendar events for 2026
🔲 Apply for 2 missing data.go.kr datasets: **모집요강** (admissions guidelines) + **교육부_고등교육기관** (MoE school registry)
🔲 Fix Dataset #1 (academyinfo SchoolInfoService) — returns `resultCode=99`; needs KCUE manual activation
🔲 **~200 more universities** to onboard (we have 12 of ~330+)
🔲 Junior colleges (~130 institutions, not started)
🔲 Clean up 6 dead `ADAPTER_REGISTRY` placeholder entries

---

## Phase 3 — Extraction Quality (PDF → structured data)

**Status:** 5/5 field groups working on KAIST. PDF download chain limited to 1 of 12 sources.

✅ **calendar** field-group — clean
✅ **tuition** field-group — clean
✅ **scholarships** field-group — clean
✅ **documents_required** field-group — clean
✅ **requirements** field-group — **today's fix**, 3/3 schema-clean on staging
🔲 **Non-KAIST PDF download chain** — 10 of 12 sources currently produce 0 parsed PDFs (KU, Inha, JBNU, Jeju, Hanyang, CBNU, SKKU, Konkuk, Kangwon, Yonsei all hit JS-mediated download forms; need adapter-level work)
🔲 **EasyOCR** for scanned PDFs (ADR-002 chose it; no code written yet — scanned Korean PDFs silently produce empty extractions)
🔲 Widen `review_queue.reason` CHECK constraint (currently 5 values; loses signal on what kind of failure occurred)

---

## Phase 4 — Translation (Multi-language data)

**Status:** 4 languages live, 306 translations done. Coverage gap on parsed-PDF data.

✅ Vietnamese (vi), Mongolian (mn), English (en), Uzbek (uz) live
✅ 306 translations across 11 institutions (announcement titles + institution names)
✅ Papago + DeepL + Claude fallback pipeline
✅ Glossary protection for canonical Korean terms (외국인전형, etc.)
⏳ Decide what to do with **jovial-wiles worktree's uncommitted "drop Papago" rework** (22 modified files, not on any branch)
🔲 Translate the **parsed PDF content itself** (currently only titles get translated; deadlines / requirements / scholarships text stays Korean)
🔲 Russian, Chinese — if foreign-student cohort needs them

---

## Phase 5 — Production Deployment (Going live, 24/7)

**Status:** code is live on staging; production move + observability still pending.

✅ Staging Supabase fully provisioned with uni-db data
✅ Hetzner systemd timers ready (4 + Adiga = 5)
✅ data.go.kr API key in `.env`
✅ **Branch pushed to GitHub** (today — closes the 33-unpushed-commit data-loss risk)
🔲 Install Adiga systemd timer on Hetzner (files ready; needs one SSH session)
🔲 Move from staging → production Supabase project
🔲 Sentry / monitoring DSN configured (currently empty in .env)
🔲 pg_cron schedule for scraper jobs (audit mentions this for production)
🔲 PDF cache retention policy (currently no cleanup)
🔲 Rotate the leaked Gmail password from `3ae39a73-...jsonl` transcript (🟥 CRITICAL from audit)
🔲 Cleanup: 8 merge-dead `claude/*` branches + `youthful-shannon-0b1dc4` + main stash
🔲 Commit pre-existing untracked items in main repo: `20260512124000_enable_rls_audit_v2.sql`, audit doc, handoff folder

---

## Phase 6 — User Experience (Flutter app integration)

**Status:** the Hanguk Flutter app exists but doesn't yet read from the new institutions schema. Counselor HITL UI doesn't exist.

✅ Flutter app exists (12 platforms, l10n done in vi/mn/uz/en/ru/ko)
⏳ Flutter app reads new `institutions` schema partial (some `name_uz` vs `name_en` inconsistencies flagged in build plan)
🔲 Migrate users from legacy `universities` table refs to `institutions` (table dropped; app may still reference)
🔲 **Counselor HITL UI** — admin dashboard for `review_queue` (currently no UI, only DB rows)
🔲 Foreign-student facing views (search by TOPIK level, tuition range, region)
🔲 Push notifications for application deadlines (use `cycle_dates` data + FCM/APNS)
🔲 In-app PDF viewer (signed-URL access to `guideline-blobs` bucket)
🔲 Counselor partnership panels (ADR-007 deferred; future scope)

---

## Overall progress

| Phase | Done | Remaining |
|---|---:|---:|
| 1. Foundation | 5 | 2 |
| 2. Data Sources | 3 | 5 |
| 3. Extraction Quality | 5 | 3 |
| 4. Translation | 4 | 3 |
| 5. Production Deployment | 4 | 8 |
| 6. User Experience | 1 (+1 partial) | 7 |
| **Total** | **22 done** | **28 remaining** |

**Roughly 44% complete** by task count. Path to 100%:
- **Next quick win (~1 hr SSH session):** install the Adiga systemd timer on Hetzner → Phase 5 closes one item, calendar auto-refreshes weekly.
- **Highest-value remaining work:** Phase 3 non-KAIST PDF download chain — unlocks parsed guidelines for 10 universities at once.
- **Biggest unknown:** Phase 6 UX work — depends on product decisions (which views matter to users) more than tech.

## Today's session — summary

| Task | Result |
|---|---|
| Audit of recent uni-db changes | Done (full report at [UNIVERSITY_DB_CHANGE_AUDIT_2026-05-17.md](UNIVERSITY_DB_CHANGE_AUDIT_2026-05-17.md)) |
| data.go.kr task | Closed — key in .env, 4 KCUE datasets verified |
| Adiga adapter task | Closed — scheduleAjax.do integration, 27 events backfilled to staging |
| KAIST requirements hallucination | Closed — schema + prompt fix, 3/3 clean on staging |
| Branch push | Done — 33 commits to origin |
| Anthropic spend today | $0.093 (well under any budget) |
