-- Phase 5 (freshness): track when refresh_worker last revisited a source.
--
-- Distinct from fetched_at (when bytes were last downloaded) and from
-- updated_at: even a no-op poll (304 / sha unchanged) bumps last_checked_at.
-- This is what gives the worker "oldest first" rotation and lets the dashboard
-- show "average days since last check".
set local search_path = public, pg_catalog;

alter table public.guideline_documents
  add column if not exists last_checked_at timestamptz;

comment on column public.guideline_documents.last_checked_at is
  'Phase 5: when refresh_worker last revisited this source for upstream changes. NULL = never checked.';

-- Partial index — only the CURRENT (non-superseded) docs feed the worker's
-- "oldest first" rotation. Conditional so a large pipeline doesn't scan
-- ancient superseded rows on every poll.
create index if not exists guideline_documents_last_checked_at_idx
  on public.guideline_documents (last_checked_at nulls first)
  where superseded_by_id is null;

-- Surface freshness signals on the health view so the dashboard can flag
-- accumulating staleness. Appended (CREATE OR REPLACE VIEW can only add new
-- columns at the END, not reorder).
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
  (select count(*) from public.review_queue where status = 'approved')                            as review_approved,
  (select count(*) from public.review_queue where published_outcome = 'held')                     as review_held,
  (select count(*) from public.admission_cycles where status = 'unverified')                      as cycles_unverified,
  -- Phase 5 freshness signals:
  (select count(*) from public.review_queue
    where published_outcome = 'held' and resolved_at < now() - interval '7 days')                 as held_over_7d,
  (select count(*) from public.guideline_documents
    where superseded_by_id is null and last_checked_at is null)                                   as gd_never_checked,
  (select extract(day from (now() - min(last_checked_at)))::int
     from public.guideline_documents
    where superseded_by_id is null and last_checked_at is not null)                               as gd_oldest_check_age_days;

comment on view public.v_uni_db_health is
  'Phase 8 ops dashboard. Phase 5 freshness: held_over_7d (review items withheld >7d), gd_never_checked / gd_oldest_check_age_days (refresh-worker coverage). cycles_unverified flags cycles awaiting a human year/term check.';
