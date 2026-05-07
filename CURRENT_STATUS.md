# CURRENT_STATUS — read-only audit, 2026-05-07

> Snapshot of where the Hanguk repo + Korean university DB project stands
> right now, taken directly from the working tree and `.git/` (the bash
> sandbox was unavailable for this audit, so everything below is from
> `Read`/`Glob`/`Grep` against the file tree).
>
> Reference points from previous sessions:
> - Phase 0 commit `13f52ec` on `claude/vigorous-haibt-f28e2d`
> - Phase 1 commit `212f578` on the same branch
>
> Anything ambiguous is tagged **(needs user confirmation)**.

---

## 1. Branches and worktree state

### Facts

Loose refs and per-worktree HEADs read from `.git/refs/heads/` and
`.git/worktrees/*/HEAD`:

| Ref | Commit | Where it lives |
|---|---|---|
| `refs/heads/main` | `c6c8d47` | top-level checkout `C:\Users\User\Desktop\Hanguk\` |
| `refs/remotes/origin/main` | `c6c8d47` | (in sync with local main) |
| `refs/heads/claude/vigorous-haibt-f28e2d` | **`83cc097`** | worktree `.claude/worktrees/vigorous-haibt-f28e2d/` — **Phase 0/1 + 4 follow-ups** |
| `refs/heads/claude/angry-almeida-fe9d21` | `c6c8d47` | worktree `.claude/worktrees/angry-almeida-fe9d21/` (already merged into main) |
| `refs/heads/claude/quirky-taussig-671986` | `c6c8d47` | worktree exists, no branch progress |
| `refs/heads/claude/infallible-hofstadter-868266` | `43382a5` | older worktree, predates Phase 0 base |
| `refs/heads/claude/youthful-shannon-0b1dc4` | `c6c8d47` | branch exists, no commits past base **(needs user confirmation — when/why was this branch created?)** |
| `refs/remotes/origin/claude/angry-almeida-fe9d21` | `43382a5` | only remote-tracking claude branch; lags behind local |

### Inference

- `main` is unchanged since Phase 0/1 work began. Nothing from
  `vigorous-haibt-f28e2d` has been merged into it yet.
- Phase 0/1 work and all four follow-up commits live exclusively on
  `claude/vigorous-haibt-f28e2d`, which is **not** pushed to origin.
- A new branch `claude/youthful-shannon-0b1dc4` was created (no
  commits) — **(needs user confirmation)** about its intent.

---

## 2. Commits since Phase 1 (`212f578`)

### Facts

From `.git/worktrees/vigorous-haibt-f28e2d/logs/HEAD`, four commits
landed on the Phase 0/1 branch after `212f578`, all on 2026-05-07
(today, in roughly two-hour gaps):

| # | SHA | Subject | UTC time |
|---|---|---|---|
| 1 | `9cfcce7` | `fix(uni_db): clear Phase 0/1 analyzer warnings` | 2026-05-07 05:16 |
| 2 | `65479df` | `fix(uni_db): six bugs surfaced by first real pytest run` | 2026-05-07 06:11 |
| 3 | `9a8830c` | `feat(uni_db): deploy Phase 0+1 to staging Supabase + smoke-test` | 2026-05-07 08:39 |
| 4 | `83cc097` | `docs(uni_db): record §O answers as ADRs 001–010` | 2026-05-07 13:32 |

### Inference

- The user spent a full work-day on this branch today, going from
  Phase 1 scaffolding → analyzer-clean → first real pytest pass → live
  staging deploy → all ten §O questions converted to ADRs.
- No commit since `212f578` touches main — the branch is a clean
  forward chain on top of Phase 1.
- Commit (3) is the most consequential: it claims the migrations were
  pushed to a real Supabase staging project and smoke-tested. §3 below
  corroborates this with on-disk evidence.

---

## 3. Working-tree state right now

### Facts — main checkout (`C:\Users\User\Desktop\Hanguk\`)

`main` is at `c6c8d47`, but the working tree contains **uncommitted**
files that are not in that commit:

- `UNIVERSITY_DB_AUDIT.md` (root)
- `UNIVERSITY_DB_BUILD_PLAN.md` (root)
- `INTERVIEW_QA_REPORT.md` (root) — dated 2026-05-06
- `docs/samples/README.md` + 12 archetype anchor files
  (`archetype-A-snu.md` through `archetype-H-inha-tech.md`)
- `flutter_run.log` (most recent run 2026-05-06 20:03)
- `pubspec.yaml`: a `pointycastle: ^3.9.1` line was added under
  `dependency_overrides:` with comment "QA fix 2026-05-06: …"
- `pubspec.lock`: `pointycastle: dependency: "direct overridden"`,
  resolved to a 3.x version (the override took effect)
- No `services/` directory in main checkout
- No `lib/features/uni_db/`, no `lib/core/feature_flags/`

### Facts — worktree `vigorous-haibt-f28e2d`

This is the active branch (`claude/vigorous-haibt-f28e2d` at
`83cc097`). Every Phase 0/1 file is committed here:

- `services/uni_db/` populated with ~70 source files (plus a
  populated `.venv/` and `.pytest_cache/`)
- `supabase/migrations/` has the original 6 baseline files PLUS 18
  uni_db migrations (see §5)
- `lib/features/uni_db/` exists with 15 dart files
- `lib/core/feature_flags/uni_db_flag.dart` (default `false`)
- `docs/decisions/` 11 files (README + ADRs 001–010)
- `docs/credentials.md`
- `services/uni_db/PHASE_1_NOTES.md`
- **`supabase/.temp/`** with 9 CLI-generated artifacts indicating an
  active Supabase link (see §6)
- `pubspec.yaml` `dependency_overrides:` has only `freezed_annotation`
  and `vapi` — **no `pointycastle` override here.** This is a
  divergence from main's working-tree fix.

### Inference

- The user is doing the uni_db work in the worktree, and unrelated
  QA / sample-curation work in the main checkout. The two trees are
  conceptually independent right now.
- Main's working tree carries an unfinished QA-fix story:
  `pointycastle 3.9.1` override + Phase 0/1 design docs + 12
  archetype anchor samples, none committed.
- The `pointycastle` override in main pubspec.yaml/lock has **not been
  ported into the Phase 0/1 worktree**. Either (a) the worktree's
  pub-resolution doesn't trip the same `dart_jsonwebtoken` ↔
  `pointycastle 4.0.0` clash because the lockfile resolves earlier, or
  (b) the worktree will fail the same way the next time someone runs
  `flutter pub upgrade` there. **(needs user confirmation)** before
  flipping `UNI_DB_ENABLED=true` from the worktree.

---

## 4. The `services/uni_db/` Python service

### Facts

- ~70 `.py` files under `src/uni_db/`, ~25 test files (unit +
  integration + 8-archetype fixtures)
- `.venv/` exists with pinned versions (numpy 2.4.4, pymupdf 1.27.2,
  anthropic SDK installed, httpx, respx, pytest, mypy, ruff)
- `.pytest_cache/` exists — pytest has been run at least once
- `Makefile` provides `install / lint / typecheck / test / review-digest`
  targets
- `src/uni_db/extract/llm_anthropic.py` still contains
  `raise NotImplementedError(...)` in `_call_anthropic` — the live
  Anthropic call site is wired but not implemented
- `src/uni_db/parse/ocr_naver_clova.py` still contains
  `raise NotImplementedError(...)` for the live path — but this is
  intentional per ADR-002 (see §7)
- `PHASE_1_NOTES.md` describes the diff between Phase 0 and Phase 1
  (archetype dispatcher, prompt assembler, cost estimator, Korean
  date/number/table parsers, HITL views, reviewer assignment, Markdown
  digest, Flutter integrations, end-to-end test)
- README still says "Phase 0 status (2026-05-07). Scaffolded. No live
  API calls; no live crawls; no live DB writes" — and lists 14
  migrations, but the migrations folder now has 18 (see §5).

### Inference

- The Python service is in much better shape than after Phase 1: it
  now has an actually-tested archetype classifier, prompt assembler,
  and end-to-end pipeline test fixtures for archetypes A–H.
- "Six bugs surfaced by first real pytest run" (commit 2) means the
  test suite was actually executed — the `.pytest_cache` and `.venv`
  on disk are consistent with that.
- The `services/uni_db/README.md` is now slightly stale (it counts 14
  migrations and predates the four review-decisions / view migrations
  added on 20260605). **(low-priority doc lag, not blocking.)**
- Anthropic and Naver Clova OCR call sites remain `NotImplementedError`
  — this is **expected**: ADR-002 chose EasyOCR over Clova, and
  Anthropic live calls are gated on owner sign-off + the
  `UNI_DB_LIVE_APIS` flag, neither of which has been activated.

---

## 5. Supabase migrations

### Facts

Worktree `supabase/migrations/` contains 24 SQL files:

- 6 pre-existing baseline files (`20260505*` and `20260506*`) — the
  ones that were already in `main` before Phase 0
- 1 baseline placeholder `00000000000001_lovable_baseline.sql`
- 13 Phase 0 `20260601*_uni_db_v1_*` migrations (institutions →
  legacy_compat → seeds)
- 4 Phase 1 `20260605*_uni_db_v1_*` migrations
  (review_decisions, review_views, reviewer_assignment,
  recent_changes_view)

The placeholder file:

- File **was renamed** from `00000000000001_lovable_baseline.sql.PLACEHOLDER`
  to `00000000000001_lovable_baseline.sql` (no extension) — but the
  contents are still the **temporary stand-in** from Phase 0, not a
  real `supabase db dump`. The file's own header explicitly says:
  "TEMPORARY STAGING BASELINE … TO COMPLETE before any production
  deployment".

Main checkout `supabase/migrations/` has only the original 6 files.
No uni_db migrations there.

### Inference

- The user kept the placeholder file's contents but stripped the
  `.PLACEHOLDER` suffix so the Supabase CLI would actually pick it up
  as a migration (it ignores files with non-`.sql` extensions). This
  is consistent with running `supabase db push` against staging — and
  it's why staging was OK (the placeholder is a self-contained
  `create extension` + `create table profiles if not exists`), but
  it's still **not safe for production** because it doesn't reflect
  the actual production schema.
- 18 uni_db migrations now (matches §A "Phase 0 = 14 + Phase 1 = 4 =
  18" — exactly the 18 the prior prompt expected).
- No new migrations beyond Phase 1's four. Phase 2 work has not
  started in this folder.

---

## 6. Live Supabase linkage

### Facts

`supabase/.temp/` exists in the worktree (NOT in main) with these
artifacts:

| File | Contents |
|---|---|
| `project-ref` | `nhjzbjzhmugcmzchzxlv` |
| `linked-project.json` | `{"ref":"nhjzbjzhmugcmzchzxlv","name":"hanguk-staging","organization_id":"yhlbxgfpdydghudipzfk","organization_slug":"yhlbxgfpdydghudipzfk"}` |
| `pooler-url` | `postgresql://postgres.nhjzbjzhmugcmzchzxlv@aws-1-ap-northeast-2.pooler.supabase.com:5432/postgres` |
| `postgres-version` | `17.6.1.113` |
| `cli-latest` | `v2.98.2` |
| `gotrue-version`, `rest-version`, `storage-version`, `storage-migration` | present |

No `supabase/config.toml` and no `supabase/.branches/`.

No `.env` files anywhere in the worktree (only `.env.example` under
`services/uni_db/`). One `.env` exists in a different worktree
(`infallible-hofstadter-868266`), unrelated to uni_db.

### Inference

- **The user successfully linked the Supabase CLI to a real staging
  project** named `hanguk-staging` (ref `nhjzbjzhmugcmzchzxlv`),
  hosted in `ap-northeast-2` (Seoul) — matching ADR-010's data
  residency decision.
- The `postgres-version` and `*-version` files are populated with
  real values Supabase only returns over a live connection, so the
  `supabase link` succeeded against a reachable backend.
- Combined with commit `9a8830c` ("deploy Phase 0+1 to staging
  Supabase + smoke-test"), this is strong evidence that **the 18
  uni_db migrations are now applied on `hanguk-staging`.**
- **Production has not been linked.** No `prod` project-ref file, no
  `.branches/` directory. ADR-010 mentions a separate production
  project also in Seoul, but the CLI here is currently pointed at
  staging only.
- No `.env` file at the repo root for the Flutter side either —
  Supabase URL/anon are still hardcoded in `AppConfig`/`main.dart`
  per the QA report's S5 finding.

---

## 7. The `§O` open-questions list — closed

### Facts

`docs/decisions/` (worktree only) contains:

- `README.md` indexing the 10 ADRs
- ADRs 001–010, all `Status: Accepted` (or "Skipped / deferred" for
  008), all dated 2026-05-07

| ADR | Decision |
|---|---|
| 001 — Budget | Accept $300/mo steady, $960/mo burst (with internal-tool reframe to ~$30–80/mo) |
| 002 — OCR vendor | **EasyOCR** (open-source) — not Naver Clova |
| 003 — Crawler placement | **Hetzner VPS CX22** (Helsinki/Falkenstein), provisioned in Phase 2 |
| 004 — Uzbek translation | Stay at **Phase 3** with a native Uzbek-speaker reviewer |
| 005 — HITL reviewer #2 | **In-office** worker, TOPIK 4+, ~10 h/week |
| 006 — `is_partner` flag | **Keep separate** from recruitment data |
| 007 — Premium tier | **Internal-only**, no public discovery, no $4.99 tier — the system is for contracted Hanguk students only |
| 008 — Counselor mode | **Deferred** (Hanguk staff are the counselors) |
| 009 — PDF blob access | **Cached PDFs accessible** to authenticated app users via 15-minute signed URLs (Supabase Storage, not R2 — cost-driven shift per ADR-007) |
| 010 — Data residency | **Seoul (ap-northeast-2) confirmed** for prod and staging Supabase |

### Inference — this is the biggest unblock since Phase 1

- ADR-007 (internal-only) has wide downstream effects that PHASE_1_NOTES
  doesn't yet reflect: it suspends Plan §J unit-economics, defers
  Plan §K (counselor partnership), and makes the cost ceiling much
  lower than originally sized.
- ADR-002 changes the OCR plan from a budgeted $80/mo Clova
  integration to free EasyOCR. The current
  `parse/ocr_naver_clova.py` stub stays, but Phase 2 should land a
  new `parse/ocr_easyocr.py`.
- ADR-009 changes the storage plan from Cloudflare R2 to **Supabase
  Storage** (`guideline-blobs` bucket) — saves a vendor and matches
  ADR-010's Seoul residency.
- ADR-007 + ADR-008 together make the "counselor mode" branch in
  ADR-006/008 dead-letter for now; only `uni_db_reviewer` and
  `student` roles matter operationally.

`PHASE_1_NOTES.md` still lists §O as unresolved ("…Phase 1 didn't get
any answers…"); that note is now stale and should be regenerated to
reflect ADRs 001–010.

---

## 8. Flutter app side

### Facts

`lib/features/uni_db/` (worktree) contains 15 files:

```
data/uni_db_providers.dart
data/recent_changes_provider.dart
domain/institution_summary.dart
domain/upcoming_deadline.dart
domain/recruitment_target.dart
domain/recent_change.dart
presentation/institution_detail_screen.dart
presentation/institution_compare_screen.dart
presentation/application_tracker_screen.dart
presentation/notification_settings_screen.dart
presentation/widgets/coming_soon_card.dart
presentation/widgets/verified_deadline_card.dart
presentation/widgets/verified_deadlines_overlay.dart
presentation/widgets/home_recent_changes_banner.dart
presentation/widgets/university_specific_cta.dart
```

Cross-cutting integrations (worktree):

- `lib/features/applications/presentation/applications_tab.dart` —
  imports and renders `HomeRecentChangesBannerSliver` and
  `VerifiedDeadlinesOverlaySliver` as slivers above the user's free-text
  applications list. Both render `SizedBox.shrink()` when the flag is
  off.
- `lib/features/training/presentation/widgets/interview_setup_view.dart`
  — imports and renders `UniversitySpecificSetupAddon` when the user
  picks `university_specific` session type, otherwise renders nothing.
- `lib/core/router/app_router.dart` — registers the four uni_db routes
  conditionally: `if (kUniDbEnabled) ..._uniDbRoutes()`.

`lib/core/feature_flags/uni_db_flag.dart`:

```dart
const bool kUniDbEnabled = bool.fromEnvironment(
  'UNI_DB_ENABLED', defaultValue: false,
);
```

Several screens (`institution_detail_screen.dart`,
`application_tracker_screen.dart`) still render `ComingSoonCard`
when the data is empty — the empty-state copy says "Phase 1 lights
up the cycle-aware tracker" / "Per-institution detail wires up in
Phase 2".

### Inference

- The Flutter side IS wired up to the Phase 1 widgets, but they all
  short-circuit when `kUniDbEnabled=false` (the default). Production
  Chrome/web build behaviour is unchanged.
- The "Coming soon" stubs are intentionally not yet built out for the
  per-institution detail and tracker screens — those are
  Phase 2 deliverables.
- The `university_specific` interview path is now wired, gated by the
  same flag, and falls back to "Try general interview" if no
  recruitment data is verified yet — matching PHASE_1_NOTES §H.4.

---

## 9. Build / run state

### Facts

- `pubspec.yaml` version is `1.0.18+2031` (worktree and main, both
  unchanged)
- Main `pubspec.lock` has `pointycastle: dependency: "direct overridden"`
  — fix from `INTERVIEW_QA_REPORT.md` is in effect on main
- Worktree `pubspec.lock` has `pointycastle: dependency: transitive,
  version: "4.0.0"` — the override is **not** present here
- `flutter_run.log` (main only) shows a successful Chrome web build on
  2026-05-06 20:03, with `PUB_CACHE=D:\pub_cache` and
  `TMP=D:\flutter_temp` env overrides — the C-drive-full /
  D-drive-relocation workaround from the QA report is still active in
  the main shell environment
- The web app booted, Supabase init logged, then logged "user is null,
  returning empty list" twice — auth gate kept the user on the welcome
  screen
- No `flutter_run.log` in the worktree

### Inference

- Main is **buildable** today (Chrome web demonstrably booted on
  2026-05-06). The pointycastle/dart_jsonwebtoken P0 from the QA
  report is resolved on main.
- The worktree may or may not build cleanly today. If `flutter pub
  upgrade` is run there, it will resolve `pointycastle 4.0.0` and hit
  the same compile-time clash. **(needs user confirmation — does the
  worktree's `dart analyze` / `flutter test` pass?)** Commit
  `9cfcce7` is "clear Phase 0/1 analyzer warnings" so analysis must
  have run at least once on the worktree, but build/test status is
  not directly visible from disk.
- The D-drive relocation appears to be a per-shell environment
  variable rather than a system-wide install change. The C-drive
  capacity issue is **not** resolved at the OS level — only worked
  around for one shell.

---

## 10. Deltas in unrelated areas

### Facts

- `lib/features/applications/`: ~10 dart files, the only Phase 0/1
  modification is the import + sliver insertion in `applications_tab.dart`.
  No new providers or routes specific to applications.
- `lib/features/training/`: ~15 dart files, only modification is the
  `UniversitySpecificSetupAddon` insertion in `interview_setup_view.dart`.
- No new top-level directories beyond `services/`, `docs/decisions/`,
  and `docs/samples/` (latter is uncommitted in main only).
- No `infra/`, no `scripts/`, no `tools/` directory created.
- `pubspec.yaml` deps unchanged in worktree apart from
  `dependency_overrides` exclusion of pointycastle.

### Inference

The Phase 0/1 branch is admirably narrow in scope: the only
non-uni_db files it touches are two integration sites
(`applications_tab.dart` and `interview_setup_view.dart`) and the
router. Everything else is additive, behind the flag.

---

## 11. Open-questions / decisions log

### Facts — answer artifacts

The §O answers live in `docs/decisions/001-*.md` … `010-*.md`
(worktree only). No `OPEN_QUESTIONS_ANSWERS.md`, no
`DECISIONS_LOG.md`, no `KICKOFF.md` exists anywhere.

ADR-001 carries the most consequential reframe: §J's $300/mo budget
is now **suspended** at the unit-economics level because of ADR-007
(internal-only). Realistic monthly burn is reframed as $30–80.

`docs/credentials.md` (worktree only) is the run-list for activating
each integration. It is **un-edited** since Phase 1 — no completion
checkmarks.

### Inference

- The §O blockers from PHASE_1_NOTES are formally answered. Phase 2
  work can start.
- `docs/credentials.md` has not been touched since being written, so
  no live API keys appear to have been wired into a `.env` (and
  there's no `.env` next to `.env.example` to inspect).
- ADR-007's "internal-only" reframe means the §J budget math, the
  Plan §K customer-success FTE plan, and the Phase 4/5 public-API
  + counselor-mode roadmap are all officially deferred — Phase 2's
  scope shrinks accordingly.

---

## ✅ Confirmed completed since Phase 1

Direct disk evidence:

1. **Analyzer-clean Phase 0/1.** Commit `9cfcce7`. (no on-disk
   artifact, but the message + timestamp are in
   `.git/worktrees/.../logs/HEAD`).
2. **Pytest suite executed.** Commit `65479df` plus on-disk
   `.pytest_cache/` and a populated `.venv/` under
   `services/uni_db/`. Six bugs were apparently fixed in that pass.
3. **Supabase CLI linked to `hanguk-staging` (ref
   `nhjzbjzhmugcmzchzxlv`, Seoul region).** `supabase/.temp/` files
   carry Postgres 17.6.1.113 and CLI v2.98.2 — values only obtainable
   from a live connection.
4. **Phase 0+1 migrations applied to staging (high confidence).**
   Commit `9a8830c` says "deploy Phase 0+1 to staging Supabase +
   smoke-test"; combined with point 3, the 18 uni_db migrations are
   on staging. Smoke-test details aren't on disk — see §13 question
   4.
5. **All ten §O questions converted to ADRs 001–010.** All accepted
   on 2026-05-07 (commit `83cc097`).
6. **Phase 1 Flutter integrations are wired up** behind
   `kUniDbEnabled`: applications-tab slivers, interview-setup
   addon, four routes registered conditionally.
7. **`pointycastle 3.9.1` override on main** unblocks the Chrome
   web build (per `flutter_run.log` 2026-05-06).

## 🔧 In-flight or partial

1. **`00000000000001_lovable_baseline.sql` is still the
   temporary-shim placeholder.** The filename was de-`.PLACEHOLDER`'d
   so staging push could pick it up, but its contents do NOT come
   from a real `supabase db dump --linked`. Production push would
   ship a profiles-only schema instead of the actual production
   tables. **Has to be regenerated before any prod push.**
2. **`pointycastle` override is on main but not on the Phase 0/1
   worktree.** Flutter analyzer ran on the worktree
   (commit `9cfcce7`), so it built once, but a future `flutter pub
   upgrade` there would re-trigger the QA report's P0. Needs
   porting.
3. **Live API call sites still raise `NotImplementedError`.** `_call_anthropic`
   in `extract/llm_anthropic.py` and `ocr_pdf_bytes` (Naver Clova
   live path) still throw. ADR-002 deprecates Clova in favour of
   EasyOCR, so the Naver site can stay stubbed; Anthropic remains
   the gating activation step.
4. **`docs/credentials.md` is un-edited** — no live keys appear to
   be in a `.env`. The whole "credentials walkthrough" hasn't been
   run end-to-end.
5. **`PHASE_1_NOTES.md` is now stale** — it still describes §O as
   unresolved. Should be replaced (or pointed at) by the ADRs.
6. **`services/uni_db/README.md` lists 14 migrations** rather than
   the actual 18. Doc lag, no functional impact.
7. **Main checkout has uncommitted Phase 0/1 design docs**
   (`UNIVERSITY_DB_AUDIT.md`, `UNIVERSITY_DB_BUILD_PLAN.md`,
   `INTERVIEW_QA_REPORT.md`, `docs/samples/*`, the `pointycastle`
   override). None of these are on the worktree branch either.
   **(needs user confirmation — should these go to main, to the
   Phase 0/1 branch, or to a new branch?)**
8. **The Phase 0/1 branch has not been pushed to origin.** No
   `refs/remotes/origin/claude/vigorous-haibt-f28e2d` exists.
9. **A new branch `claude/youthful-shannon-0b1dc4`** was created at
   `c6c8d47` with no commits yet. **(needs user confirmation —
   intent unknown.)**

## ❓ What we should ask the user before resuming (ranked)

1. **Is staging `hanguk-staging` (`nhjzbjzhmugcmzchzxlv`) the
   intended target, and are the migrations applied cleanly?**
   Disk says yes; we want a verbal confirm + a sanity peek at the
   staging DB before we treat it as canonical.
2. **Where do we route the in-progress design docs in the main
   checkout?** Options: (a) commit them onto `main` directly,
   (b) cherry into `claude/vigorous-haibt-f28e2d` and let it
   propagate via PR, (c) new branch. Same question for the
   `pointycastle` override + the `docs/samples/*` archetype anchors
   + `INTERVIEW_QA_REPORT.md`.
3. **Do we want to mirror the `pointycastle` override into the
   Phase 0/1 worktree right now**, before any further work there?
   Otherwise the next `flutter pub upgrade` will re-trigger the QA
   report's P0.
4. **Was the staging smoke-test passing**, and what did it cover?
   The commit message says "smoke-test", but no test report is on
   disk. (We can re-run it, or accept the green-light from the
   user.)
5. **Are the §O ADR decisions final**, or should any be re-debated
   before Phase 2 work starts? Specifically ADR-007 (internal-only)
   has the largest blast radius — confirm we're really cancelling
   the public + premium roadmap.
6. **What is `claude/youthful-shannon-0b1dc4` for?** It's an empty
   branch sitting at `c6c8d47`. If unintended, we can prune it.
7. **For Phase 2 kickoff, is the priority order:**
   (a) Replace `00000000000001_lovable_baseline.sql` with a real
   `supabase db dump` against production, (b) provision the
   Hetzner VPS (ADR-003), (c) build `parse/ocr_easyocr.py`
   (ADR-002), or (d) wire `extract/llm_anthropic._call_anthropic`?
8. **Do we want to merge `claude/vigorous-haibt-f28e2d` into `main`
   now** (with `kUniDbEnabled=false` keeping production behaviour
   identical), or hold the branch until Phase 2 is also ready?

---

**Reading back into this on next session:**

```
Worktree branch:   claude/vigorous-haibt-f28e2d @ 83cc097
Worktree path:     C:\Users\User\Desktop\Hanguk\.claude\worktrees\vigorous-haibt-f28e2d
Main branch:       main @ c6c8d47 (working tree dirty: design docs +
                   pointycastle override + samples + INTERVIEW_QA_REPORT.md)
Staging Supabase:  hanguk-staging (nhjzbjzhmugcmzchzxlv, ap-northeast-2)
Phase 0+1 schema:  applied to staging via supabase db push (commit 9a8830c)
§O answers:        ADR 001–010 in docs/decisions/ (worktree)
Live integrations: still mocked behind UNI_DB_LIVE_APIS=false
Feature flag:      kUniDbEnabled=false default; --dart-define=UNI_DB_ENABLED=true to test
```

---

Report path: `C:\Users\User\Desktop\Hanguk\CURRENT_STATUS.md`
