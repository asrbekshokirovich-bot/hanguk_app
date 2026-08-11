-- Guest Explorer's list and card data, read live instead of hand-copied.
--
-- The app carried `lib/features/guest/domain/approved_uni_details.dart`: a
-- 93-entry map of institution id → tuition range, application window, document
-- deadline, TOPIK floor, interview and English flags. Its own docstring calls
-- it a "snapshot copied verbatim from the DB", taken 2026-08-08.
--
-- A snapshot goes stale the moment a guideline is approved, and this one had
-- already needed a hand-patch — commit e50db63, "add 6 missing approved
-- universities + fix intake years". Between that snapshot and today the
-- catalogue moved from 48 approved institutions to 57 (2026: 7 → 13,
-- 2027: 41 → 55): twenty (institution, year) pairs a student could not see,
-- and no way to notice except by someone re-running the export.
--
-- This view is that export, evaluated on read. One row per
-- (institution, intake year) the review queue has actually published, so a
-- guideline approved today reaches the app on its next refresh and each field
-- fills in as extraction covers it — no file to regenerate, no build to ship.
--
-- Superseded cycles are excluded: a cycle is superseded exactly when a newer
-- document replaced it, so the survivor decides what the year offers.
--
-- Anon-readable by design — Guest Explorer runs before login. It exposes only
-- what the guest cards already show, and nothing student-identifying.

drop view if exists public.v_guest_approved_admissions;

create view public.v_guest_approved_admissions
  with (security_invoker = on) as
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
  tuition_year as (
    select cy.institution_id,
           cy.intake_year,
           (select max(t.academic_year) from public.tuition t
             where t.institution_id = cy.institution_id
               and t.academic_year <= cy.intake_year) as ty
      from cyc cy
  )
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

         -- Requirements hang off the cycle. The FLOOR across tracks, because a
         -- student wants the lowest bar that gets them in, not the highest.
         (select min(r.topik_min_level) from public.requirements r
            join public.admission_cycles c2 on c2.id = r.cycle_id
           where c2.institution_id = cy.institution_id
             and c2.intake_year = cy.intake_year
             and c2.status <> 'superseded') as topik_min_level,
         (select bool_or(r.interview_required) from public.requirements r
            join public.admission_cycles c2 on c2.id = r.cycle_id
           where c2.institution_id = cy.institution_id
             and c2.intake_year = cy.intake_year
             and c2.status <> 'superseded') as interview_required,
         -- `english_test` is jsonb, not text: "an English test is named
         -- anywhere in this year's requirements", which is what the card
         -- claims. Not a promise that English alone suffices — no column
         -- states that.
         (select bool_or(r.english_test is not null
                         and jsonb_typeof(r.english_test) = 'object'
                         and r.english_test <> '{}'::jsonb)
            from public.requirements r
            join public.admission_cycles c2 on c2.id = r.cycle_id
           where c2.institution_id = cy.institution_id
             and c2.intake_year = cy.intake_year
             and c2.status <> 'superseded') as english_accepted
    from cyc cy
    join tuition_year ty
      on ty.institution_id = cy.institution_id
     and ty.intake_year = cy.intake_year
    join public.institutions i
      on i.id = cy.institution_id;

comment on view public.v_guest_approved_admissions is
  'Guest Explorer''s list AND its per-card detail, one row per (institution, '
  'intake year) the review queue has published. Carries the institution '
  'display fields so Explore lists from here rather than from '
  'v_institutions_for_map, whose is_visible_on_map gate hides 10 institutions '
  'that do have published data. tuition_academic_year names the year a fee '
  'belongs to — Korean guidelines quote the current year''s fees in next '
  'year''s 모집요강. Null fields mean the approved review did not provide that '
  'value; the card shows a dash rather than a guess.';

grant select on public.v_guest_approved_admissions to anon, authenticated;
