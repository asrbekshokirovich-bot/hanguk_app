# Migration baseline — replace before any production push

The file `00000000000001_lovable_baseline.sql` in this directory is a
**minimal staging shim** (creates `public.profiles` only). It is NOT
the production schema floor — it does not contain `payments`,
`scheduled_payments`, `student_budgets`, `university_documents`,
`app_versions`, `interview_sessions`, `interview_messages`, `documents`,
`student_suggestions`, `university_rooms`, `room_channels`,
`channel_messages`, `university_events`, `system_settings`, or any of
the other tables that exist in the Hanguk 2026 production project.

## Why it's a shim

The Phase 0 + Phase 1 staging push happened from a Windows machine that
did not have Docker installed; the Supabase CLI's `db dump` command
runs `pg_dump` inside a versioned Docker container, so without Docker
we could not capture the real prod schema in the same session.

The shim was sufficient for staging because we side-parked the 6
pre-existing prod-shape migrations during that push (they're back in
`supabase/migrations/` now). Staging therefore validates the new
`uni_db_v1_*` migrations in isolation, on a fresh project that knows
nothing about Hanguk's prod tables. **That is fine for staging. It is
NOT fine for production.**

## What to do before pushing to production

When you (the operator) have:

1. **Docker Desktop** running (`docker version` returns success), AND
2. **Supabase CLI authenticated** (`supabase login` already done), AND
3. **A clean working tree on `claude/vigorous-haibt-f28e2d`**

run, from the worktree root:

```powershell
& "$env:LOCALAPPDATA\Programs\Supabase\supabase.exe" link --project-ref lysjdtyanhdfphqyijsr
& "$env:LOCALAPPDATA\Programs\Supabase\supabase.exe" db dump --linked `
  > supabase\migrations\00000000000001_lovable_baseline.sql
```

Project ref `lysjdtyanhdfphqyijsr` is **Hanguk 2026** (the production
project — verified against `lib/core/config/app_config.dart:supabaseUrl`).

`supabase db dump` defaults to schema-only when neither `--data-only`
nor `--role-only` is passed (the older `--schema-only` flag was
removed in CLI 2.98+; default behaviour matches it).

## Sanitize the result

Open the dumped file and **strip these line categories** before
committing — they refer to project-specific roles or session GUCs that
fail when applied to a fresh project:

- Any `ALTER … OWNER TO …;`
- Any `COMMENT ON ROLE …;`
- Any `GRANT … TO postgres;` for cluster-level roles (table-level
  grants are fine)
- `SET default_table_access_method` and other session-only `SET`s
  outside `set local search_path = …`

Re-run `supabase db push --linked --dry-run` against staging after the
dump to confirm the migration ordering still resolves cleanly. Expect
the staging project to need a reset (drop schema + replay) since the
old shim has incompatible RLS policies.

## DO NOT push to production until this is regenerated

The production push (`supabase db push --linked` against
`lysjdtyanhdfphqyijsr`) **must** run after this baseline file contains
the real prod schema. Pushing the shim against prod would attempt to
re-create `public.profiles` (idempotent — fine) and then fail on
subsequent migrations that reference tables the shim doesn't bring in.
More dangerous, the dump may reveal RLS / trigger / function semantics
the new uni_db migrations conflict with — better to find that on
staging via dry-run than on prod via failed transaction.

## Stamp the file when done

Once you replace the shim with the real dump, also update:

- `services/uni_db/PHASE_1_NOTES.md` — strike the "shim" line
- `docs/credentials.md` — strike the same caveat
- `CURRENT_STATUS.md` — note the baseline is real
- This `MIGRATION_BASELINE_TODO.md` — delete it

The CI smoke test (`scripts/smoke_test_uni_db.sql`) should keep working
unchanged after the swap.
