-- ============================================================================
--  uni_db v1 staging smoke test
--
--  Run via:
--    supabase db query --linked --file scripts/smoke_test_uni_db.sql
--
--  Each SELECT carries its own descriptive alias so the JSON / table
--  output reads like a checklist. Expected values are inline.
-- ============================================================================

-- 1. uni_db tables present (expected: 24)
select 'uni_db_tables_found' as check_name, count(*) as observed, 24 as expected
  from information_schema.tables
 where table_schema='public'
   and table_name in (
     'institutions','recruitment_units','programs','recruitment_unit_programs',
     'admission_cycles','cycle_dates','requirements','tuition',
     'scholarships','documents_required','guideline_documents',
     'announcement_sources','announcements','crawl_runs','crawl_findings',
     'change_events','extraction_jobs','review_queue','review_decisions',
     'user_tracked_universities','user_alerts','translations',
     'term_glossary','embedding_chunks');

-- 2. uni_db views present (expected: 9)
select 'uni_db_views_found' as check_name, count(*) as observed, 9 as expected
  from information_schema.views
 where table_schema='public' and table_name like 'v_%';

-- 3. RLS enabled on user-scoped tables (expected: every row rowsecurity=true)
select 'rls_'||tablename as check_name, rowsecurity::text as observed, 'true' as expected
  from pg_tables
 where schemaname='public'
   and tablename in (
     'user_tracked_universities','user_alerts',
     'review_decisions','institutions');

-- 4. Top-15 institution glossary seeded (expected: 30)
select 'glossary_institution_rows' as check_name, count(*) as observed, 30 as expected
  from public.term_glossary
 where category='institution_name' and authoritative=true;

-- 5. Announcement sources seeded (expected: 19)
select 'announcement_sources_rows' as check_name, count(*) as observed, 19 as expected
  from public.announcement_sources;

-- 6. plpgsql round-robin function returns null when no reviewers (expected: null)
select 'fn_pick_next_reviewer' as check_name,
       coalesce(public.fn_pick_next_reviewer()::text, '<null>') as observed,
       '<null>' as expected;

-- 7. Recent-changes view safe for anon (expected: 0)
select 'recent_changes_for_anon' as check_name, count(*) as observed, 0 as expected
  from public.v_user_recent_changes;
