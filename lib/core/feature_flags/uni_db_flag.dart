/// Feature flag for the University DB system (plan §H).
///
/// Default `false` so production builds are unaffected by the in-progress
/// Phase 0 work in `services/uni_db/` and the new schema migrations.
///
/// Flip to `true` only when:
///   1. The migrations in `supabase/migrations/2026060100*.sql` have been
///      applied to the target Supabase project.
///   2. The seed migrations have populated `announcement_sources` and
///      `term_glossary`.
///   3. The legacy compat view (Phase 1) is in place so `universities`
///      reads still work.
///
/// At compile time:  `--dart-define=UNI_DB_ENABLED=true`
/// At runtime:       always `false` for now (no remote-config plumbed).
const bool kUniDbEnabled = bool.fromEnvironment(
  'UNI_DB_ENABLED',
  defaultValue: false,
);
