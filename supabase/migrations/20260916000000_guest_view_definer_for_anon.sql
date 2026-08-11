-- The guest view answered 401 to the exact audience it was built for.
--
-- v_guest_approved_admissions was created `security_invoker = on`, so a
-- query runs under the caller's own RLS. But the uni_db base tables are
-- internal-only: their select policies require public.fn_is_app_user()
-- (20260606000100_uni_db_v2_internal_only_rls.sql), and `anon` does not even
-- hold EXECUTE on that function. So Guest Explore — which runs before login,
-- as anon, the one caller this view exists for — got
--   42501: permission denied for function fn_is_app_user
-- and the app showed "Universitetlarni yuklab bo'lmadi" on every open.
-- The db-side verification queries all ran as service role, which sails past
-- RLS, so the counts looked right while the real audience was locked out.
--
-- Recreate the view as security DEFINER (the Postgres default for views): it
-- reads the base tables as its owner, and the anon/authenticated grants on
-- the view itself decide who may call it. That is the intended shape here —
-- the view exposes only the fields the guest cards already show, nothing
-- student-identifying, which is exactly the curated-public-subset case
-- definer views exist for. The base tables stay internal-only.

drop view if exists public.v_guest_approved_admissions;

create view public.v_guest_approved_admissions as
  with cyc as (
    select distinct
           c.institution_id,
           c.intake_year,
           c.intake_term
      from public.admission_cycles c
     where c.status <> 'superseded'
  ),
  -- Korean guidelines quote the CURRENT year's fees as a reference, so a 2027
  -- 모집요강 carries a table stamped 2026 — every tuition row in the catalogue
  -- today is academic_year 2026 while most cycles are 2027. Matching the years
  -- strictly showed a fee on 2 of 70 rows. Take the newest year at or below the
  -- intake instead, and carry that year out so the card can say which year's
  -- fee it is showing rather than implying it is the intake's.
  --
  -- `distinct` because this is keyed by (institution, year) while `cyc` is
  -- keyed by (institution, year, term), and it is joined on the first two.
  -- Without it an institution running both a spring and a fall intake in one
  -- year matched twice and every one of its rows was duplicated — Korea
  -- Aerospace 2027 came out as 4 rows instead of 2.
  tuition_year as (
    select distinct
           cy.institution_id,
           cy.intake_year,
           (select max(t.academic_year) from public.tuition t
             where t.institution_id = cy.institution_id
               and t.academic_year <= cy.intake_year) as ty
      from cyc cy
  ),
  -- Requirements per (institution, intake year), split by whether the cycle
  -- holding them is still live. Aggregated once here rather than as six
  -- correlated subqueries, so the fallback is a coalesce rather than a
  -- repeated scan.
  --
  -- The floor across tracks for TOPIK, because a student wants the lowest bar
  -- that gets them in, not the highest.
  req as (
    select c.institution_id,
           c.intake_year,
           min(r.topik_min_level)
             filter (where c.status <> 'superseded') as topik_live,
           min(r.topik_min_level)
             filter (where c.status =  'superseded') as topik_sup,
           bool_or(r.interview_required)
             filter (where c.status <> 'superseded') as interview_live,
           bool_or(r.interview_required)
             filter (where c.status =  'superseded') as interview_sup,
           -- `english_test` is jsonb, not text: "an English test is named
           -- anywhere in this year's requirements", which is what the card
           -- claims. Not a promise that English alone suffices — no column
           -- states that.
           bool_or(r.english_test is not null
                   and jsonb_typeof(r.english_test) = 'object'
                   and r.english_test <> '{}'::jsonb)
             filter (where c.status <> 'superseded') as english_live,
           bool_or(r.english_test is not null
                   and jsonb_typeof(r.english_test) = 'object'
                   and r.english_test <> '{}'::jsonb)
             filter (where c.status =  'superseded') as english_sup
      from public.requirements r
      join public.admission_cycles c on c.id = r.cycle_id
     group by 1, 2
  ),
  -- Required documents per (institution, intake year). Counted by distinct
  -- `document_type` rather than by row: the table carries one row per
  -- (applicant category, document), so SeoulTech's 12 rows are the same few
  -- papers repeated across categories, and a raw count would read as a longer
  -- list than a student actually files.
  --
  -- No superseded fallback here — no superseded cycle in the catalogue holds a
  -- document row, so there is nothing to fall back to and no reason to invite
  -- a stale list.
  docs as (
    select c.institution_id,
           c.intake_year,
           count(distinct dr.document_type)
             filter (where dr.is_required) as required_document_count,
           bool_or(dr.is_apostille_required) as apostille_required
      from public.documents_required dr
      join public.admission_cycles c on c.id = dr.cycle_id
     where c.status <> 'superseded'
     group by 1, 2
  ),
  admissions as (
  select cy.institution_id,
         cy.intake_year,
         cy.intake_term,

         -- Display fields, so Guest Explore builds its list from THIS view
         -- rather than from v_institutions_for_map. That view is gated on
         -- is_visible_on_map, false for 10 institutions that do have published
         -- admission data — Dong Seoul alone has 14 cycles. On a screen whose
         -- whole promise is "the universities we have researched", a
         -- map-visibility flag is the wrong gate.
         i.name_ko,
         i.name_ko_short,
         coalesce(i.display_names ->> 'en', i.name_en) as name_en,
         coalesce(i.display_names ->> 'uz', i.name_en, i.name_ko) as name_uz,
         i.city_ko,
         i.tier,
         i.ieqas_status,
         i.is_partner,
         i.primary_domain,
         i.logo_url,

         ty.ty as tuition_academic_year,
         -- Tuition is keyed by (institution, academic_year), not by cycle: one
         -- row per faculty group, so the card shows the spread across them.
         (select min(t.amount_krw) from public.tuition t
           where t.institution_id = cy.institution_id
             and t.academic_year = ty.ty) as tuition_min_krw,
         (select max(t.amount_krw) from public.tuition t
           where t.institution_id = cy.institution_id
             and t.academic_year = ty.ty) as tuition_max_krw,
         (select max(t.admission_fee_krw) from public.tuition t
           where t.institution_id = cy.institution_id
             and t.academic_year = ty.ty) as admission_fee_krw,

         -- Periods are keyed by (institution, year, semester). Earliest open
         -- and latest close across rounds, so the window covers the whole
         -- intake rather than whichever round happens to sort first.
         (select min(p.application_start) from public.university_admission_periods p
           where p.institution_id = cy.institution_id
             and p.year = cy.intake_year
             and p.semester = cy.intake_term) as application_start,
         (select max(p.application_end) from public.university_admission_periods p
           where p.institution_id = cy.institution_id
             and p.year = cy.intake_year
             and p.semester = cy.intake_term) as application_end,
         (select max(p.document_deadline) from public.university_admission_periods p
           where p.institution_id = cy.institution_id
             and p.year = cy.intake_year
             and p.semester = cy.intake_term) as document_deadline,

         coalesce(rq.topik_live, rq.topik_sup) as topik_min_level,
         coalesce(rq.interview_live, rq.interview_sup) as interview_required,
         coalesce(rq.english_live, rq.english_sup) as english_accepted,

         coalesce(dc.required_document_count, 0) as required_document_count,
         dc.apostille_required
    from cyc cy
    join tuition_year ty
      on ty.institution_id = cy.institution_id
     and ty.intake_year = cy.intake_year
    join public.institutions i
      on i.id = cy.institution_id
    left join req rq
      on rq.institution_id = cy.institution_id
     and rq.intake_year = cy.intake_year
    left join docs dc
      on dc.institution_id = cy.institution_id
     and dc.intake_year = cy.intake_year
  )
  -- Drop the hollow rows: an approved cycle with not one extracted field. A
  -- university on a screen that promises researched ones, opening onto a card
  -- of dashes, is worse than one that is absent.
  select *
    from admissions
   where tuition_min_krw is not null
      or application_start is not null
      or application_end is not null
      or document_deadline is not null
      or topik_min_level is not null
      or interview_required is not null
      or english_accepted is not null
      or required_document_count > 0;

comment on view public.v_guest_approved_admissions is
  'Guest Explorer''s list AND its per-card detail, one row per (institution, '
  'intake year) the review queue has published. SECURITY DEFINER on purpose: '
  'Guest Explore runs before login, as anon, and the base tables'' RLS is '
  'internal-only (fn_is_app_user), so an invoker view answered 42501 to its '
  'one real audience. The view exposes only what the guest cards show and '
  'nothing student-identifying; access is governed by the grants below. '
  'required_document_count counts DISTINCT required document types. TOPIK, '
  'interview and English fall back per field to superseded cycles where no '
  'live cycle states them. Rows with no extracted field at all are excluded.';

grant select on public.v_guest_approved_admissions to anon, authenticated;
