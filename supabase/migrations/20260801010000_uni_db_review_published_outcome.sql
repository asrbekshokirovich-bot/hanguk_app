-- Track B (observability): record WHY a processed review item did or didn't
-- reach the public tables.
--
-- publish_worker holds past-cycle items (the staleness guard) and skips empty
-- ones, but until now that outcome was invisible: a held item looked identical
-- to a published one (both only had `published_at` set), so `v_uni_db_health`
-- reported `review_published = 0` even right after publishing 3 items. This adds
-- a dedicated outcome column — kept separate from `review_queue.status` so the
-- human's review decision ('approved') stays distinct from the publish result.
set local search_path = public, pg_catalog;

alter table public.review_queue
  add column if not exists published_outcome text
    check (published_outcome in ('published', 'held', 'skipped'));

comment on column public.review_queue.published_outcome is
  'publish_worker outcome: published (reached public tables) | held (past-cycle source, withheld) | skipped (empty/unknown). NULL = not yet processed.';

-- Backfill the 8 items publish processed on 2026-05-26: 3 published (undated /
-- current), 5 held as stale (cdu 2017, gnu/knsu/hanyang 2022, hanseo-sch 2025).
-- Idempotent (`and published_outcome is null`) so a re-run is a no-op.
update public.review_queue set published_outcome = 'published'
 where id in ('767c4f85-ad32-45ed-aab0-48221ff914bc',   -- gimcheon scholarships
              '68e9e699-f6c3-47fa-ab9d-0d5c9efe8054',   -- cju requirements
              'cafaec40-e968-4b98-8ba7-e4fccf6ca26c')   -- hanseo requirements
   and published_outcome is null;

update public.review_queue set published_outcome = 'held'
 where id in ('321bc21a-88af-43cc-942f-d813081386fc',   -- gnu calendar (2022)
              '1895ff14-7b80-42d4-8479-66157b220645',   -- hanyang requirements (2022/2023)
              '9b599e12-e27b-4fbd-ba12-c93b03b81211',   -- knsu calendar (2022)
              'ce52df8e-dc80-4e40-8cf8-9c0b432fd5a6',   -- hanseo scholarships (2025)
              '2a377354-9f34-46e0-9d04-8c0773c9ab06')   -- cdu requirements (2017)
   and published_outcome is null;

-- Recreate the health view: read the real publish/hold split from the new
-- column (review_published was counting status='promoted', which publish never
-- sets — hence the perpetual 0), and surface cycles awaiting a human year check.
-- CREATE OR REPLACE can only change a column's expression in place and append
-- new columns at the END, so the original 17 columns keep their name+order
-- (review_published's expression is swapped) and the 3 new metrics are appended.
create or replace view public.v_uni_db_health
with (security_invoker = true) as
select
  (select count(*) from public.announcement_sources where status = 'live')                       as live_sources,
  (select count(*) from public.announcement_sources where notes like 'Promoted from proposed_sources%') as promoted_sources,
  (select count(*) from public.proposed_sources where status = 'pending_review')                  as proposed_pending,
  (select count(*) from public.guideline_documents)                                               as documents_total,
  (select count(*) from public.guideline_documents where parse_status = 'succeeded')              as documents_parsed,
  (select round(100.0 * count(*) filter (where status = 'succeeded') / nullif(count(*), 0), 1)
     from public.extraction_jobs where started_at > now() - interval '30 days')                   as extract_success_pct_30d,
  (select count(*) from public.review_queue where status = 'open')                                as review_open,
  (select count(*) from public.review_queue where published_outcome = 'published')                as review_published,
  (select count(*) from public.review_queue where status = 'rejected')                            as review_rejected,
  (select count(*) from public.admission_cycles)                                                  as cycles,
  (select count(*) from public.requirements)                                                      as pub_requirements,
  (select count(*) from public.tuition)                                                           as pub_tuition,
  (select count(*) from public.scholarships)                                                      as pub_scholarships,
  (select count(*) from public.documents_required)                                                as pub_documents,
  (select count(*) from public.university_admission_periods)                                       as pub_periods,
  (select count(*) from public.translations)                                                      as translations,
  now()                                                                                           as as_of,
  -- appended metrics (Track B):
  (select count(*) from public.review_queue where status = 'approved')                            as review_approved,
  (select count(*) from public.review_queue where published_outcome = 'held')                     as review_held,
  (select count(*) from public.admission_cycles where status = 'unverified')                      as cycles_unverified;

comment on view public.v_uni_db_health is
  'Phase 8 ops dashboard: pipeline counts. review_published/review_held read publish_worker''s published_outcome; cycles_unverified flags cycles awaiting a human year/term check.';
