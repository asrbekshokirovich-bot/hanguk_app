# University Database — Change Audit

**Date:** 2026-05-17
**Auditor:** Claude Opus 4.7 (1M, session `6ec88794`) running in worktree `loving-fermi-e1bbfb`
**Scope:** Every uni-db–relevant change on this PC since `f269a3c` (main tip), across all 13 local branches, all 3 worktrees, and every Claude session transcript under `C:\Users\User\`.

---

## 1. TL;DR

- **11 uni-db commits** on branch `claude/store-readiness-p0-p1` over 2026-05-14 → 2026-05-15 — added P1–P3 adapters (SNU, KU, KAIST), P4 Tracks 1–4 (parse pipeline, Playwright/Yonsei, upstream skeletons, vi+mn translations), 7 more live universities (CBNU, JBNU, SKKU, Inha, Kangwon, Jeju, Hanyang, Konkuk), schema relaxation, LLM timeout fix, and the `.env` pydantic crash fix.
- **End state:** 12 live sources · 91–97 announcements in DB · 306 translations · 3 KAIST PDFs parsed end-to-end via Claude.
- **"Multiple Claude accounts?" — No.** Every preserved transcript (17 sessions across 16 worktrees) belongs to the same Claude userID `1121797f0c3dc…`. The perceived account split is a **git identity** switch: `asrbekshokirovich-bot` (2026-05-07→05-11) → `Asrbek (via Claude)` (2026-05-11→present). One Claude identity, two git configs.
- **Logical author of the recent uni-db work:** a single conversation, the "hardcore-clarke handoff", preserved twice on disk as sessions `33c9c64f` and `5cb09344` (Claude Code re-opened it when the project-folder string changed). Same first prompt, same 11 commit messages, same last timestamp.
- **🟥 CRITICAL — credential leak:** transcript `…\Hanguk\3ae39a73-…jsonl` (line 1) contains a plaintext Gmail address and password the user pasted as their GitHub login. **Rotate the password and scrub the line before sharing.**
- **🟥 CRITICAL — 31 unpushed commits** on `claude/store-readiness-p0-p1` (entire uni-db P1–P4 stack plus pre-uni-db audit fixes). If this PC dies, the work is gone.
- **🟧 HIGH — uncommitted uni-db rework** in worktree `jovial-wiles-a59c96`: 20 modified + 1 deleted + 1 untracked file implementing "drop Papago, Claude-only translation" (new ADR `011-drop-papago-claude-only.md`, deleted `papago.py`, modified `glossary/models/pipeline.py`, test rewrites, `PHASE_3_DESIGN.md` rewrite). Not committed, not pushed, not present on any other branch. Will be lost if the worktree is deleted, and likely conflicts with the translate-pipeline commits already on `store-readiness-p0-p1`.
- **🟧 HIGH — untracked migration** in main checkout: `supabase/migrations/20260512124000_enable_rls_audit_v2.sql` plus the new `handoff/2026-05-14-uni-db-next-session/` folder are present-but-untracked on `store-readiness-p0-p1`.
- **🟨 MEDIUM** — branch `claude/youthful-shannon-0b1dc4` is a divergent fork (21 ahead / 49 behind main) that pre-dates uni-db and deletes the entire `services/uni_db/` and `infra/` trees. Decide explicitly: merge cherry-picks or delete.

---

## 2. "Multiple Claude accounts" — what the evidence actually shows

| Question | Answer | Evidence |
|---|---|---|
| Multiple Claude *accounts* used on this PC? | **No — single account.** | `~/.claude.json` contains exactly one `userID 1121797f0c3dcbcc96e50b83d2700dd3edce44705bb0776e55b2cc871e0909a1`. No `~/.claude/.credentials.json`. No `oauthAccount`, no second workspace. All 17 session JSONLs share the same identity fingerprint. |
| Multiple Claude *sessions*? | **Yes — 17 distinct sessions** across 16 worktree branches over 2026-05-04 → 2026-05-17. | 17 top-level `.jsonl` files under `~/.claude/projects/C--Users-User-Desktop-Hanguk*/`. |
| Different *commit authors* on git history? | **Yes — two git identities.** | `asrbekshokirovich-bot` (Phase 0/1/2/3, 2026-05-07→05-11). `Asrbek (via Claude)` (everything from 2026-05-11 onwards including the recent P1–P4 uni-db work). Switch boundary: last bot commit 2026-05-11 12:35:03, first "Asrbek" commit 2026-05-11 20:15:41. |
| Same conversation re-opened? | **Yes — `33c9c64f` and `5cb09344` are the same logical session** persisted twice on disk because the project-folder string changed mid-session. | Identical first user prompt ("Pick up the Hanguk university database (uni_db) work…"), identical 11 commit messages, identical last timestamp `2026-05-15 12:35 UTC`. |

**Reading:** when you said "many of changes by another claude accounts too", what's actually on disk is *one* Claude account driving *multiple worktree-isolated sessions*, with the local git author switching once. There's no foreign Claude installation contributing commits.

---

## 3. File-level changes per commit (`claude/store-readiness-p0-p1`)

Newest → oldest, chronological per commit. Subsystem groupings.

### `1d56529` — P4 Phase E: Konkuk live (12th source) (2026-05-15)
- **adapters:** M `configs/__init__.py`, M `configs/konkuk.py` — real selectors replacing placeholder; **Chrome User-Agent override** (server filters `HangukUniDBBot`); `wait_until="domcontentloaded"` (networkidle never settles).
- **scripts:** A `_konkuk_drill.py`, `_konkuk_full_row.py`, `_reset_due.py`, `_seed_konkuk.py`.
- **DB delta:** 12 live sources; 97 announcements total.

### `74c5393` — P4 Phase C+D: 3 KAIST PDFs + 273 title translations (2026-05-15)
- **workers:** M `workers/translate_worker.py` — `PENDING_SQL` now UNION across `institutions.name_ko` ∪ `announcements.title_ko`.
- **scripts:** A `_count_translations.py`, `_inspect_parseable.py`, `_sample_ann_translations.py`, `_translate_dryrun.py`.
- **DB delta:** guideline_documents 1 → 3 · extraction_jobs 5 → 15 · translations 12 → 306.

### `cd3dff6` — P4 Phase A+B: schema relaxation + LLM timeout fix (2026-05-15)
- **extract:** M `extract/schemas.py` — all 5 JSON schemas: root `additionalProperties False → True`; calendar `event_type` enum widened 13 → 19; scholarships/documents-required allow `notes_ko`, `correction_text_ko`, `is_correction_notice`, `extractor_confidence`.
- **extract:** M `extract/llm_anthropic.py` — timeout 30 s → 120 s; retries 4 → 2; closing fence regex made optional.
- **tests:** M `tests/unit/test_translation.py` — monkeypatch Papago/DeepL creds in 4 tests.
- **DB delta:** extraction_jobs success 0/5 → 4/5 (only `requirements` field group still hallucinates → HITL).

### `2b4198d` — Inha, Kangwon, Jeju, Hanyang live (2026-05-15)
- **adapters:** M `configs/__init__.py`; A `configs/hanyang.py`; M `configs/inha.py`, `configs/jeju.py`, `configs/kangwon.py`.
- **adapters:** M `html_list_adapter.py` — concat row `onclick` with link `onclick` for `external_id` (enables Hanyang's `<li onclick>`).
- **adapters:** M `json_api_adapter.py` — `list_path` + `detail_path_template` on `KuBbsConfig`.
- **scripts:** A `_inha_post_body.py`, `_jeju_probe.py`, `_probe_round_4.py`, `_probe_round_5.py`, `_reset_kangwon.py`, `_seed_round_2.py`.
- **DB delta:** 54 → 91 announcements; 7 → 11 institutions.

### `05e7ffc` — CBNU, JBNU, SKKU live (2026-05-15)
- **adapters:** M `configs/__init__.py`, `configs/cbnu.py`, `configs/jbnu.py`; A `configs/skku.py`; M `discovery/keywords_ko.py` — `EXTRA_ALLOWED_HOSTS` for `skku.edu`.
- **scripts:** A `_cbnu_adapter_debug.py`, `_cbnu_httpx_probe.py`, `_dump_rows.py`, `_probe_8_schools.py`, `_probe_drilled_urls.py`, `_probe_round_3.py`, `_seed_new_three.py`.
- **DB delta:** 33 → 54 announcements; 4 → 7 institutions.

### `8240e49` — fix: strip inline `# comments` from `.env` values (2026-05-15)
- M `.env.example`, A `scripts/_strip_env_comments.py`.
- **Why:** `pydantic-settings` was parsing `UNI_DB_LIVE_APIS=true   # …` literally → bool coercion crash. Systemd timer had been crashing every 4 h since deploy.

### `0e16e47` — P4 Track 4: vi + mn translations + glossary bugfix (2026-05-14)
- **translate:** M `translate/pipeline.py` — graceful fallback to Claude when provider creds missing.
- **translate:** M `translate/glossary.py` — **bugfix:** pre-translate used `enumerate(candidates)`, post-translate used `enumerate(hits)`; mismatch left `⟪G:N⟫` placeholders unresolved for any non-zero glossary index.
- **scripts:** A `_check_translate_keys.py`, `_inspect_translations.py`, `run_translate_once.py`.

### `f6cba83` — P4 Track 3: upstream adapter skeletons (2026-05-14)
- **new package:** A `upstream/__init__.py`, `upstream/data_go_kr.py`, `upstream/adiga.py`.
- **scripts:** A `_probe_public_data.py`.
- **Status:** architecture-only. `DATA_GO_KR_APP_KEY` and `ADIGA_APP_KEY` are empty strings in production `.env`.

### `e9f26df` — P4 Track 2: Playwright adapter, Yonsei live (2026-05-14)
- **adapters:** A `playwright_list_adapter.py`; M `html_list_adapter.py` — `posted_at_regex`, extended `external_id_regex`; M `configs/yonsei.py` — real selectors + factory functions; M `configs/__init__.py` wires Yonsei factories.
- **scripts:** A `_playwright_probe.py`, `_update_yonsei_url.py`, `_yonsei_links.py`, `_yonsei_rows.py`.
- **DB delta:** 4 Yonsei announcements; running total 33.

### `616712a` (`616771d`) — P4 Track 1: parse pipeline end-to-end (KAIST PDF → Claude → DB) (2026-05-14)
- **workers:** M `workers/parse_worker.py` — exception routing to HITL, JSON fence fix, `_failed_result` helper.
- **scripts:** A `_fix_env.py`, `_inspect_parse.py`, `_inspect_state.py`, `_link_institutions.py`, `_reset_one.py`, `_seed_institutions.py`, `run_parse_once.py`.

### `1b602a6` — P1–P3: SNU/KU/KAIST adapters + discovery script + systemd timer (2026-05-14)
- **adapters:** A `configs/{__init__,snu,kaist,korea_univ,yonsei,konkuk,inha,cbnu,jbnu,kangwon,jeju}.py` (placeholders for univs not yet live); A `json_api_adapter.py`.
- **scripts:** A `scripts/_remote_test.py`, `scripts/run_discovery_once.py`.
- **DB delta:** 10 SNU + 9 KU + 10 KAIST = 29 announcements live.

---

## 4. Adapter inventory (12 live universities)

| University | Config file | Source type | Parser | Live count | Top fragility |
|---|---|---|---|---:|---|
| **SNU** 서울대 | `configs/snu.py` | Static HTML (eGov) | `HtmlListAdapter`, regex `bbsidx=(\d+)` | 10 | Detail-page PDF download chain not wired |
| **KU** 고려대 | `configs/korea_univ.py` | JSON API (FR_BBS_SVC) | `JsonApiAdapter/KuBbsConfig` | 9 | `url_ko=MENU_ID=700` but adapter silently fetches `MENU_ID=1700` — auditing on `url_ko` won't find the real endpoint |
| **KAIST** | `configs/kaist.py` | JSON API (Wizdom CMS) | `JsonApiAdapter/WzBoardConfig` | 10 (+3 PDFs) | `requirements` field group still hallucinates → HITL |
| **Yonsei** 연세대 | `configs/yonsei.py` | JS-rendered ASP/JS | `PlaywrightListAdapter` | 4 | `posted_at_regex` extracts date from inline KR text — brittle |
| **Inha** 인하대 | `configs/inha.py` | JSON API | `JsonApiAdapter/KuBbsConfig` (custom `list_path`) | 15 | Vestigial `INHA_SELECTORS` placeholder kept for import compat; PDF chain not wired |
| **Kangwon** 강원대 | `configs/kangwon.py` | Static HTML (eGov BBS) | `HtmlListAdapter` | 10 | No URL-level 재외국민 filter — all categories enter `announcements`, must be filtered downstream |
| **Jeju** 제주대 | `configs/jeju.py` | JS-rendered (div-table) | `PlaywrightListAdapter` | 10 | Dead `ipsi.jejunu.ac.kr` placeholder still in `ADAPTER_REGISTRY` |
| **Hanyang** 한양대 | `configs/hanyang.py` | JS-rendered, `<li onclick>` | `PlaywrightListAdapter` | 2 | `external_id` capture depends on the row-onclick concat patch in `2b4198d`; silent zero-row failure if onclick template changes |
| **CBNU** 충북대 | `configs/cbnu.py` | Static HTML (eGov BBS) | `HtmlListAdapter` | 11 | Board cadence is low; last upstream activity Aug 2024 |
| **JBNU** 전북대 | `configs/jbnu.py` | JS-rendered (div-table) | `PlaywrightListAdapter` | 7 | Opaque encoded `menuurl=` query param — rotates if school changes menu keys; PDF chain not wired |
| **SKKU** 성균관대 | `configs/skku.py` | JS-rendered (`.edu`) | `PlaywrightListAdapter` | 3 | Requires `EXTRA_ALLOWED_HOSTS` exception; thin coverage |
| **Konkuk** 건국대 | `configs/konkuk.py` | JS-rendered (JSP, `<li onclick>`) | `PlaywrightListAdapter`, `wait_until=domcontentloaded`, Chrome UA | 6 | UA spoof hardcoded; if site updates bot-detection, silent 0-row returns |

---

## 5. Database / schema delta

The 11 recent commits do **not** touch `supabase/migrations/`. All DB-shape changes in this window are Python-side (`extract/schemas.py`, `translate_worker.PENDING_SQL`). The migration changes underpinning the live pipeline were already committed pre-`f269a3c`.

### Tables added (pre-window, applied to staging)
`institutions`, `recruitment_units`, `admission_cycles`, `cycle_dates`, `requirements`, `tuition`, `scholarships`, `documents_required`, `guideline_documents`, `announcement_sources`, `announcements`, `crawl_runs`, `crawl_findings`, `change_events`, `extraction_jobs`, `review_queue`, `translations`, `term_glossary`, `proposed_sources`, `pdf_access_log`.

### Tables dropped (`20260510130000`, pre-window)
`public.universities` CASCADE (697 rows, all test data; backup table `universities_backup_20260510` retained 1 quarter), plus `university_admissions`, `university_announcements`, `university_events`, `university_notes`, `university_staff_assignments`.

### NOT NULL → NULL loosening (same migration)
`university_id` on 9 join tables (`application_form_cache`, `…_changes`, `…_validations`, `gks_designated_universities`, `university_admission_periods`, `university_documents`, `university_programs`, `university_rooms`, `student_suggestions`) and `target_university_id` on `interview_sessions`, `study_plan_sessions`.

### RLS shift (`20260606000100`, pre-window)
All open `using (true)` / `is_visible_on_map=true` policies on uni-db tables → `fn_is_app_user()`. New role `contracted_student` added to `profiles_role_check`.

### Code-vs-schema mismatches noted
- `review_queue.reason` CHECK constraint accepts only 5 values; `parse_worker.py` coerces all failures to `'low_confidence'` (commit `616771d`: "broader vocabulary needs a migration"). **No migration filed.**
- `announcement_sources.institution_id` nullable; seeds pre-dating `_link_institutions.py` may carry `NULL`.

---

## 6. Pipeline overview

```
Adapter (HtmlListAdapter / JsonApiAdapter / PlaywrightListAdapter)
    │  configs/__init__.py → ADAPTER_REGISTRY
    ▼
discovery_worker.py
    │  dedupe on (source_id, external_post_id)
    ▼
announcements (Supabase)
    │  if PDF & MIME OK & size ≤ 20 MiB
    ▼
run_parse_once.py → guideline_documents (SHA-256, Supabase Storage)
    │
    ▼
parse_worker.py → llm_anthropic.py (120 s timeout, 2 retries, ephemeral cache)
    │  prompt_assembler.py (archetype-aware, glossary-seeded)
    │  schemas.py validates 5 field groups
    ▼
extraction_jobs (parsed JSONB) ──fail/low-conf──▶ review_queue
    │
    ▼  (parallel)
run_translate_once.py → translate/pipeline.py
    │  Papago (vi/id) · DeepL (ru/en-labels) · Claude (mn + universal fallback)
    │  glossary.py protects 고려대학교 → ⟪G:N⟫ ↔ "Korea University"
    ▼
translations
    │
    ▼
lib/features/{map,applications}/data/*_repository.dart → Flutter app
```

Schedule: pg_cron (Supabase) + systemd timers on Hetzner CX22; uni-db-{discovery-poll,extract,ocr,translate}.{service,timer}, all logging via journald (no app-level log files).

---

## 7. Branch & worktree drift

### Worktree status

| Worktree | Branch | Status | Notes |
|---|---|---|---|
| `C:\Users\User\Desktop\Hanguk` | `claude/store-readiness-p0-p1` | **13 M / 5 ??** | Most modifications are autogen Flutter l10n + plugin registrants. **Untracked & real:** `supabase/migrations/20260512124000_enable_rls_audit_v2.sql`, `docs/audits/ui_ux_audit_2026-05-12.md`, `handoff/2026-05-14-uni-db-next-session/`. Two APKs at repo root probably belong in `.gitignore`. |
| `.claude/worktrees/jovial-wiles-a59c96` | `claude/jovial-wiles-a59c96` | **20 M / 1 D / 1 ??** | **Uncommitted uni-db rework: "drop Papago, Claude-only translation".** New ADR `011-drop-papago-claude-only.md`, deleted `papago.py`, edited `glossary/models/pipeline.py`, test rewrites, `PHASE_3_DESIGN.md` rewrite, `config.py` and `cost_estimator.py` edits, runbook + credentials.md edits. Not on any branch. |
| `.claude/worktrees/loving-fermi-e1bbfb` | `claude/loving-fermi-e1bbfb` | clean | This worktree (audit). |

### Branch metadata

| Branch | Tip | Subject | Ahead/Behind main | Date | Verdict |
|---|---|---|---:|---|---|
| `claude/blissful-sammet-20b7c2` | f269a3c | Merge PR #4 | 0/0 | 05-12 | = main (safe to delete) |
| `claude/gallant-montalcini-e885ac` | 9a56fcf | chore: gitignore push creds | 0/18 | 05-09 | reachable from main |
| `claude/goofy-mcnulty-c95caa` | 9a56fcf | same | 0/18 | 05-09 | reachable from main |
| `claude/hardcore-clarke-54cb78` | f269a3c | Merge PR #4 | 0/0 | 05-12 | = main |
| `claude/jovial-wiles-a59c96` | f269a3c | Merge PR #4 | 0/0 | 05-12 | branch = main, **but worktree has uncommitted work** |
| `claude/loving-fermi-e1bbfb` | f269a3c | Merge PR #4 | 0/0 | 05-12 | = main |
| `claude/loving-jennings-10d687` | c6c8d47 | feat(updater) | 0/44 | 05-06 | reachable from main |
| `claude/practical-tu-271c6d` | c6c8d47 | feat(updater) | 0/44 | 05-06 | reachable from main |
| **`claude/store-readiness-p0-p1`** | 1d56529 | feat(uni-db) Konkuk live | **31 / 0** | 05-15 | **UNPUSHED — all uni-db work lives here** |
| `claude/training-p2-partial` | f5cf9eb | Merge PR #2 | 0/7 | 05-11 | local has 1 unpushed merge commit |
| `claude/vigorous-haibt-f28e2d` | 083e4cb | feat: uni_db cutover | 0/12 | 05-11 | reachable from main (Phase 0/1/2/3 origin) |
| **`claude/youthful-shannon-0b1dc4`** | 43382a5 | Revert Korean voice | **21 / 49** | 05-04 | **divergent fork — pre-uni-db universe** |
| `main` | f269a3c | Merge PR #4 | — | 05-12 | baseline |

### Stashes
`stash@{0}: On main: audit-task-app-store-readiness` — one stash on `main`; inspect before any cleanup.

### Cross-branch duplicate uni-db work
**None.** All uni-db commits live on a single linear history culminating in `store-readiness-p0-p1`. The only divergence is `youthful-shannon-0b1dc4` (which *deletes* uni-db) and the uncommitted jovial-wiles worktree rework.

---

## 8. Logs

The repo intentionally carries **no runtime uni-db logs**. Systemd units on the Hetzner host write to journald; there are no app-level logfiles in `infra/` or `services/`.

- `auto_deploy_log.txt` — **0 bytes**.
- `flutter_run.log` — pre-uni-db Flutter web init noise, May 6, irrelevant.
- 45 root `.txt`/`.log` dumps — **all mtime 2026-05-06**, 6 days before uni-db work began. Flutter analyzer / dart compiler output, build noise. Verified by grep: every "uni-db keyword" hit resolves to the Dart `University` class, `university_selection_view.dart`, or `supabase_flutter` init lines. **Zero scraper/parse/translate evidence.**
- `android/.kotlin/errors/*.log` + `build/.cxx/.../CMakeOutput.log` — native build noise, unrelated.

### Operational evidence (substitute source: commit-message bodies)

The P4 commit bodies are unusually detailed and capture observed runtime behaviour. Reconstructed timeline below.

#### Per-university scrape results

| University | Live commit | First-run announcements | First-run notes |
|---|---|---:|---|
| SNU | `1b602a6` | 10 | First live source; `cp1251` glyph crash on Windows console fixed |
| KU | `1b602a6` | 9 | url_ko mismatch (MENU_ID=700 vs 1700) |
| KAIST | `1b602a6` | 10 | url_ko fix to `intl-undergraduate/notice` |
| Yonsei | `e9f26df` | 4 | First JS-rendered source; needed Playwright + Chromium install |
| CBNU | `05e7ffc` | 11 | url_ko corrected |
| JBNU | `05e7ffc` | 7 | url_ko corrected |
| SKKU | `05e7ffc` | 3 | `EXTRA_ALLOWED_HOSTS` whitelist for `.edu` |
| Inha | `2b4198d` | 15 | KuBbsConfig generalised |
| Kangwon | `2b4198d` | 10 | Transient httpx ConnectTimeout on first try; recovered |
| Jeju | `2b4198d` | 10 | DNS typo `ipsi → ibsi` fixed |
| Hanyang | `2b4198d` | 2 | Row-level onclick concat patch needed |
| Konkuk | `1d56529` | 6 | Chrome UA + `wait_until=domcontentloaded` |
| **Total** | — | **97** | 12 live sources |

#### Parse pipeline (KAIST PDFs only — non-KAIST detail-page download chain not yet wired)
- `616771d` Track 1: 1st KAIST PDF; 5 extraction_jobs spawned; scholarships extracted at conf=0.85; ~$0.05/doc.
- `cd3dff6` Phase A+B: post-relaxation 4/5 field groups land real data (was 0/5); only `requirements` still fails (content quality, not timeout). Run time 8 min → <2 min.
- `74c5393` Phase C+D: 3 PDFs; 1 archetype G full extraction, 1 archetype A correctly empty (marketing PDF), 1 small fee-waiver PDF; ~$0.25 total.

#### Translation runs
- `0e16e47` Track 4: 4 institution names × (en/uz/vi/mn) verified; ~$0.02/row Claude spend.
- `74c5393` Phase D: 273 announcement-title translations (91 × 3 langs); 306 translations total across 11 institutions; ~$5.50 actual (under $7 ceiling).

#### Errors observed → fix commits

| Observed failure | Fix commit |
|---|---|
| `pydantic ValidationError` on `UNI_DB_LIVE_APIS` from inline `#` comments (systemd timer crashing every 4 h) | **`8240e49`** |
| Anthropic timeout (30 s × 4 retries) on `requirements` field group | **`cd3dff6`** Phase B: 120 s timeout, 2 retries, optional closing fence |
| Schema rejected `is_correction_notice` at root; calendar enum too narrow; documents missing optional fields → 0/5 success | **`cd3dff6`** Phase A: `additionalProperties: True`, enum widening |
| Glossary placeholder leak `고려대학교 → ⟪G:10⟫` | **`0e16e47`** index-mismatch bugfix |
| `review_queue` CHECK rejected broader HITL reasons | **`616771d`** coerce all → `low_confidence` (debt: needs migration) |
| `jsonschema.ValidationError` aborting whole doc | **`616771d`** per-field-group catch, route to HITL |
| `APITimeoutError` aborting whole doc | **`616771d`** generic exception → `_failed_result` |
| Corrupted `SUPABASE_SERVICE_ROLE_KEY` in `.env` | **`616771d`** `scripts/_fix_env.py` |
| DNS fail on `ipsi.jejunu.ac.kr` (typo, should be `ibsi`) | **`2b4198d`** seed fix |
| Yonsei `url_ko` was homepage, not notice list | **`e9f26df`** `_update_yonsei_url.py` |
| Konkuk: TLS stall on `HangukUniDBBot/0.1` UA; `networkidle` never settles | **`1d56529`** UA override + `domcontentloaded` |
| Windows console `cp1251` encode error on SNU log glyphs | **`1b602a6`** glyph replacement |
| `_load_prior_snapshots` querying wrong timestamp column | **`1b602a6`** use `detected_at` |
| Hanyang rows: no inner `<a>`, only row-level `onclick` | **`2b4198d`** concat row.onclick + link_el.onclick |
| CBNU/JBNU/Inha url_ko all pointed at homepages | **`05e7ffc`** + **`2b4198d`** url fixes |
| Pre-window pipeline bugs (`get-pdf-url` referenced non-existent `bucket` column; `fn_emit_change_event` wrong columns; 19 FK indexes missing; 7 prod fns mutable search_path) | pre-window `ee46c73` |

Every fix in the P4 series was driven by an observed, named failure — not speculative hardening.

---

## 9. CLAUDE.md sweep (PC-wide)

**Zero `CLAUDE.md` files anywhere inside `C:\Users\User\Desktop\Hanguk\` or its worktrees.**

The only `CLAUDE.md` files on the PC sit inside `C:\Users\User\.claude\downloads\everything-claude-code\` — 9 stock plugin/template files dated 2026-05-04, none referencing uni-db / Hanguk / supabase / scraper. These are installer drops, not project memory.

If you want a `CLAUDE.md` to scope future Claude sessions on this project, there isn't one to find — **one would need to be authored**.

---

## 10. Session attribution timeline

All times UTC. `?` where the JSONL head/tail didn't expose a clean first timestamp.

```
2026-05-04 04:00 → 12:24 | 3ae39a73 | opus-4-7    | HEAD (Hanguk root, pre-worktree)
                                                  │ General app work; CREDENTIAL LEAK at line 1; 6 commits.
2026-05-05 → 05-06 12:48 | 9d1459bf | opus→sonnet | claude/angry-almeida-fe9d21
                                                  │ "Localise very last version of the app"; 4 commits; 1325 asst turns.
2026-05-06 07:09 → 07:21 | dd6ba078 | sonnet-4-6  | claude/infallible-hofstadter-868266
                                                  │ APK build sidequest; 0 commits.
2026-05-06          21:01 | fd95bba5 | sonnet-4-6  | claude/quirky-taussig-671986
                                                  │ "Plan to use Anthropic for all AIs"; 3 user turns; 0 commits.
2026-05-06          12:08 | da0b721e | opus-4-7    | claude/youthful-shannon-0b1dc4
                                                  │ "Locate very last APK to desktop"; 0 commits.
2026-05-07 01:45 → 05-08 04:28 | a46a7f86 | opus-4-7 | claude/vigorous-haibt-f28e2d
                                                  │ ★ UNI_DB ORIGIN — Phase 0/1 scaffold, pytest hardening,
                                                  │   staging deploy; 10 commits as asrbekshokirovich-bot.
2026-05-08 04:25 → 05-10 12:43 | ab822cf4 | opus-4-7 | claude/stupefied-ptolemy-f00eb9
                                                  │ ★ Phase 2/3 — Anthropic gate, prod schema baseline,
                                                  │   Hetzner runbook, live extraction call;
                                                  │   24 commits as asrbekshokirovich-bot.
2026-05-08 08:20 → 13:47 | 29245435 | opus-4-7    | claude/loving-jennings-10d687
                                                  │ Disk-cleanup sidequest; 0 commits.
2026-05-08 09:32 → 16:32 | df1a16eb | opus-4-7    | claude/practical-tu-271c6d
                                                  │ CRM/telephony research sidequest; 0 commits; 9 subagents.
2026-05-08            12:27 | 2ee179c4 | (stub, 0 turns)
2026-05-10          ~09:50 | 73e635d0 | opus-4-7  | claude/gallant-montalcini-e885ac
                                                  │ EUR/USD daytrade sidequest; 0 commits.
2026-05-10          ~10:39 | 052a857b | opus-4-7  | claude/goofy-mcnulty-c95caa
                                                  │ EUR/USD daytrade sidequest; 0 commits.
2026-05-10          15:52 | 49719789 | opus-4-7    | claude/sad-dewdney-f80742
                                                  │ "Install python for one extension"; 0 commits.
─── git-author switch: asrbekshokirovich-bot → "Asrbek (via Claude)" between 2026-05-11 12:35 and 20:15 ───
─── Missing-session gap: May 11–13 commits (training/map/walkaround/android audits) not preserved as JSONLs ───
2026-05-14          ~?  → 15:22 | 5c2bcbc8 | opus-4-7 | claude/jovial-wiles-a59c96
                                                  │ "Check all the claude.mds and whole context about uni-db";
                                                  │ context loader; 1 commit invocation; 245 uni-db hits.
2026-05-14 → 05-15 12:35 | 33c9c64f | opus→sonnet | claude/hardcore-clarke-54cb78
                                                  │ ★ P4 HANDOFF SESSION — reads HANDOFF.md / CREDENTIALS_REFERENCE.md
                                                  │   / NEXT_STEPS.md; produces P1-P3 + P4 Tracks 1-4 + .env fix
                                                  │   + 7 more univs + KAIST PDFs + Konkuk live;
                                                  │   11 commits as "Asrbek (via Claude)".
2026-05-14 → 05-15 12:35 | 5cb09344 | sonnet→opus | claude/hardcore-clarke-54cb78
                                                  │ ★ SAME LOGICAL SESSION as 33c9c64f, persisted twice on disk
                                                  │   (project-folder string changed mid-session).
2026-05-17           11:00 | 6ec88794 | opus-4-7 (1M) | claude/loving-fermi-e1bbfb
                                                  │ ★ CURRENT — this audit; 4 subagents spawned.
```

### Commit → session map

| Commit window | Git author | Producing session(s) |
|---|---|---|
| 2026-05-07 → 05-08 — Phase 0/1 (`feat(uni_db): Phase 0/1 scaffold`, pytest, staging deploy) | `asrbekshokirovich-bot` | **a46a7f86** vigorous-haibt |
| 2026-05-08 → 05-10 — Phase 2/3 (SQL migrations, Edge Functions, infra/, design docs, Anthropic gate, live extraction, security advisor fixes) | `asrbekshokirovich-bot` | **ab822cf4** stupefied-ptolemy |
| 2026-05-11 — `feat: uni_db cutover to institutions`; PR #1 merge | bot + Asrbek | tail of ab822cf4 + push |
| 2026-05-11 → 05-13 — training/map/kakao/walkaround/android-fix audits (not uni-db) | `Asrbek (via Claude)` | **9d1459bf** angry-almeida + **missing JSONLs** |
| 2026-05-14 → 05-15 — **the 11 recent uni-db commits** (P1-P3, P4 Tracks 1-4, env fix, 7 more univs, KAIST PDFs, Konkuk) | `Asrbek (via Claude)` | **33c9c64f / 5cb09344** hardcore-clarke handoff (one logical session) |
| 2026-05-17 — this audit | — | **6ec88794** loving-fermi |

**Missing-session gap (May 11–13):** the training/map/android audit commits cannot be tied to a preserved JSONL on this PC. Likely causes: those sessions were wiped (`~/.claude/backups/` is empty), or the worktree folder under `~/.claude/projects/` was deleted alongside the worktree itself. The git author boundary (`bot → Asrbek (via Claude)`) coincides exactly — consistent with a local `git config user.name/user.email` change, not a different Claude installation.

### Account / identity hints

- `~/.claude.json` — single `userID 1121797f0c3dcbcc96e50b83d2700dd3edce44705bb0776e55b2cc871e0909a1`. `firstStartTime: 2026-05-03T09:48:07Z`. No `oauthAccount`/`organization`/`primaryApiKey` fields.
- `~/.claude/settings.json` — `{"autoUpdatesChannel":"latest"}` only.
- `~/.claude/.credentials.json` — does not exist.
- No `mcp.json`, `scheduled_tasks.json`, `cron.json` in `~/.claude/`. Desktop Commander MCP config at `~/.claude-server-commander/` (not uni-db relevant).
- Every preserved JSONL belongs to this single Claude userID.

---

## 11. Open issues & recommended actions

Ordered by severity.

### 🟥 CRITICAL

1. **Rotate the leaked credentials and scrub the transcript.**
   File: `C:\Users\User\.claude\projects\C--Users-User-Desktop-Hanguk\3ae39a73-9651-43f6-8250-afdbd6619cff.jsonl` — line 1 contains a plaintext Gmail address and password the user pasted as their GitHub login. **Rotate the password now. Replace line 1 with redacted text or delete the file.** (Backups: `~/.claude/backups/` is empty, so this is the only copy.)

2. **Push `claude/store-readiness-p0-p1` to origin.**
   31 unpushed commits including the entire uni-db P1–P4 stack. If this PC fails or `git gc` runs aggressively, the work is gone. Suggested:
   ```
   git -C C:/Users/User/Desktop/Hanguk push -u origin claude/store-readiness-p0-p1
   ```

### 🟧 HIGH

3. **Decide the fate of the `jovial-wiles-a59c96` worktree's uncommitted rework.**
   "Drop Papago, Claude-only translation" — 20 modified + 1 deleted + 1 untracked, including a new ADR `011-drop-papago-claude-only.md`. **This work conflicts with the translate-pipeline commits already on `store-readiness-p0-p1` (`0e16e47`, `cd3dff6`, `74c5393`).** Options:
   - **Adopt:** stage and commit in jovial-wiles, then rebase into `store-readiness-p0-p1`.
   - **Discard:** `git -C .claude/worktrees/jovial-wiles-a59c96 stash` (preserves) or `git reset --hard` (destroys — confirm first).
   Inspect first: `git -C .claude/worktrees/jovial-wiles-a59c96 diff`.

4. **Commit or stash the untracked items in main checkout.**
   - `supabase/migrations/20260512124000_enable_rls_audit_v2.sql` (real migration, not autogen)
   - `docs/audits/ui_ux_audit_2026-05-12.md`
   - `handoff/2026-05-14-uni-db-next-session/` (handoff package)
   - The 2 root APKs probably belong in `.gitignore`, not in a commit.

5. **Resolve the `youthful-shannon-0b1dc4` divergent fork** (21 ahead / 49 behind, deletes all uni-db).
   Either cherry-pick the genuinely-unique commits (auth unification, presence channels, vercel SPA routing, realtime context migration) and delete the branch, or delete outright. Don't merge as-is — it would obliterate uni-db.

### 🟨 MEDIUM

6. **Inspect the `main` stash** (`stash@{0}: audit-task-app-store-readiness`) before any cleanup. Drop it if subsumed.

7. **Widen `review_queue.reason` CHECK constraint** (debt from `616771d`). Until widened, every parse failure is logged as `'low_confidence'` regardless of actual cause, losing forensic signal.

8. **Delete dead `ADAPTER_REGISTRY` placeholders** in `configs/__init__.py` lines 86-93 (stale Yonsei/Konkuk/etc. root-URL stubs that silently 0-row on every crawl run).

9. **Decide non-KAIST PDF attachment download chain.** 10 of 12 live sources contribute 0 parsed guidelines (KU/Inha/JBNU/Jeju/Hanyang/CBNU/SKKU/Konkuk/Kangwon/Yonsei all have placeholder detail-page URLs; PDFs reached only after JS-mediated download forms).

10. **Fill the upstream gap or remove the skeletons.** `data_go_kr.py` and `adiga.py` produce no data because `DATA_GO_KR_APP_KEY` / `ADIGA_APP_KEY` are empty. Either acquire keys + wire end-to-end, or strip the skeleton to avoid "ready but inert" code drift.

### 🟩 LOW / housekeeping

11. **Delete merge-dead branches** (8 of them, all reachable from main):
    `claude/blissful-sammet-20b7c2`, `claude/hardcore-clarke-54cb78`, `claude/loving-fermi-e1bbfb` (this one, after audit), `claude/gallant-montalcini-e885ac`, `claude/goofy-mcnulty-c95caa`, `claude/loving-jennings-10d687`, `claude/practical-tu-271c6d`. (Leave `jovial-wiles-a59c96` until point 3 is resolved.)

12. **Push `training-p2-partial`** (1 unpushed merge commit) if it's intended to be on origin.

13. **Delete `services/uni_db/src/uni_db/storage/r2.py`** — raises `NotImplementedError`, docstring marked DEPRECATED, imported nowhere.

14. **`parse/ocr_naver_clova.py` is orphaned** — ADR-002 chose EasyOCR but no `parse/ocr_easyocr.py` exists yet. Scanned PDFs currently fall through to empty text silently. Either implement EasyOCR or surface an explicit "OCR unavailable" error.

15. **Update `services/uni_db/README.md`** — `CURRENT_STATUS.md` (snapshot 2026-05-07) flags it as stale ("counts 14 migrations and predates the four review-decisions / view migrations added on 20260605").

16. **Author a project `CLAUDE.md`** at `C:\Users\User\Desktop\Hanguk\CLAUDE.md` so the next Claude session loads project context automatically instead of needing handoff prompts.

---

## 12. Key files for follow-up

- Code & schema:
  - `services/uni_db/src/uni_db/discovery/adapters/configs/{__init__,snu,kaist,korea_univ,yonsei,inha,cbnu,jbnu,skku,kangwon,jeju,hanyang,konkuk}.py`
  - `services/uni_db/src/uni_db/discovery/adapters/{html_list,playwright_list,json_api}_adapter.py`
  - `services/uni_db/src/uni_db/workers/{parse,translate,discovery}_worker.py`
  - `services/uni_db/src/uni_db/extract/{schemas,llm_anthropic,prompt_assembler}.py`
  - `services/uni_db/src/uni_db/translate/{pipeline,glossary,models}.py`
  - `services/uni_db/src/uni_db/upstream/{data_go_kr,adiga}.py`
  - `supabase/migrations/20260601000005`–`20260606000200` (uni-db v1 + v2)
  - `supabase/migrations/20260510130000_uni_db_v3_drop_legacy_universities.sql`
  - Untracked: `supabase/migrations/20260512124000_enable_rls_audit_v2.sql`
- Docs (in-repo):
  - `UNIVERSITY_DB_AUDIT.md`, `UNIVERSITY_DB_BUILD_PLAN.md`, `CURRENT_STATUS.md`
  - `services/uni_db/PHASE_{1,2,3}_NOTES.md` / `PHASE_3_DESIGN.md`
- Sessions for forensic re-read:
  - `~/.claude/projects/…vigorous-haibt-f28e2d/a46a7f86-…jsonl` (Phase 0/1 origin)
  - `~/.claude/projects/C--Users-User-Desktop-Hanguk/ab822cf4-…jsonl` (Phase 2/3, note misleading parent folder)
  - `~/.claude/projects/…hardcore-clarke-54cb78/33c9c64f-…jsonl` and `…blissful-sammet-20b7c2/5cb09344-…jsonl` (P4 Tracks 1–4 + Konkuk — same logical session)
  - `~/.claude/projects/C--Users-User-Desktop-Hanguk/3ae39a73-…jsonl` (**contains credential leak — scrub before sharing**)
- Identity:
  - `C:\Users\User\.claude.json` — userID line.
