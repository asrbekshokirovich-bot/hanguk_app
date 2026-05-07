# hanguk_app

A Flutter / Supabase / Riverpod app for Korean-language learners and
visa-track applicants.

## University DB system (Phase 0 — scaffolded)

The repository now hosts a Python service layer at
[`services/uni_db/`](services/uni_db/) plus matching Supabase migrations
and Flutter routes that together build an always-fresh, Korean-source-of-truth
multilingual database of Korean university admissions.

- Plan: [`UNIVERSITY_DB_BUILD_PLAN.md`](UNIVERSITY_DB_BUILD_PLAN.md)
- Audit: [`UNIVERSITY_DB_AUDIT.md`](UNIVERSITY_DB_AUDIT.md)
- Service quickstart: [services/uni_db/README.md](services/uni_db/README.md)
- Migrations: [supabase/migrations/](supabase/migrations/) — files named
  `20260601000000_uni_db_v1_*.sql` and seeds `20260601000200_*.sql`
- Flutter integration is gated behind `--dart-define=UNI_DB_ENABLED=true`;
  default builds are unaffected.

Phase 0 status: file-level scaffolding only. No migrations applied to live
Supabase; no paid API calls; no live ac.kr fetches. See
`services/uni_db/README.md` for the list of intentionally-stubbed paths.

## Flutter quickstart

```bash
flutter pub get
flutter run                                       # default — uni_db disabled
flutter run --dart-define=UNI_DB_ENABLED=true     # enable uni_db routes
flutter test
```

A few resources for first-time Flutter contributors:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)
