-- Guest Explorer's approved-admission data, read live instead of hand-copied.
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
-- guideline approved today reaches the app on its next refresh and the fields
-- fill in as extraction covers them — no file to regenerate, no build to ship.
--
-- Superseded cycles are excluded: a cycle is superseded exactly when a newer
-- document replaced it, so the survivor decides what the year offers.
--
-- Anon-readable by design — Guest Explorer runs before login. It exposes only
-- what the guest cards already show, and nothing student-identifying.

create or replace view public.v_guest_approved_admissions
  with (security_invoker = on) as
  with cyc as (
    select distinct
           c.institution_id,
           c.intake_year,
           c.intake_term
      from public.admission_cycles c
     where c.status <> 'superseded'
  )
  select cy.institution_id,
         cy.intake_year,
         cy.intake_term,

         -- Tuition is keyed by (institution, academic_year), not by cycle: one
         -- row per faculty group, so the card shows the spread across them.
         (select min(t.amount_krw) from public.tuition t
           where t.institution_id = cy.institution_id
             and t.academic_year = cy.intake_year) as tuition_min_krw,
         (select max(t.amount_krw) from public.tuition t
           where t.institution_id = cy.institution_id
             and t.academic_year = cy.intake_year) as tuition_max_krw,
         (select max(t.admission_fee_krw) from public.tuition t
           where t.institution_id = cy.institution_id
             and t.academic_year = cy.intake_year) as admission_fee_krw,

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
         -- "An English test is named anywhere in this year's requirements",
         -- which is what the card claims. Not a promise that English alone
         -- suffices — no column states that.
         (select bool_or(r.english_test is not null and r.english_test <> '')
            from public.requirements r
            join public.admission_cycles c2 on c2.id = r.cycle_id
           where c2.institution_id = cy.institution_id
             and c2.intake_year = cy.intake_year
             and c2.status <> 'superseded') as english_accepted
    from cyc cy;

comment on view public.v_guest_approved_admissions is
  'Guest Explorer''s approved-admission rows, one per (institution, intake '
  'year), read live. Replaces the hand-maintained approved_uni_details.dart '
  'snapshot: a guideline approved today appears on the next app refresh, and '
  'each field fills in as extraction covers it. Null means the approved review '
  'did not provide that value — the card shows a dash rather than a guess.';

grant select on public.v_guest_approved_admissions to anon, authenticated;
