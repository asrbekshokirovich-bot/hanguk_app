-- Fix: students could not submit university selections for approval.
--
-- Submitting inserts a row into public.applications. The AFTER INSERT
-- trigger trg_ensure_student_intake runs ensure_student_intake(), which
-- inserts into public.student_intakes. That function was SECURITY INVOKER,
-- so the nested insert ran with the student's privileges — but
-- student_intakes RLS only grants write to staff roles (owner/admin/
-- call_operator/document_handler). Result: the whole submit failed with
--   PostgrestException 42501: new row violates row-level security policy
--   for table "student_intakes".
--
-- Make the function SECURITY DEFINER (matching the sibling
-- handle_new_application_room trigger, which already is) so the
-- system-managed intake row is created regardless of the caller's role.
-- The function only ever writes the application's own student_id /
-- intake_id and is idempotent (ON CONFLICT DO NOTHING), so widening its
-- privilege here is safe and does not let students write arbitrary
-- student_intakes rows through the API.
create or replace function public.ensure_student_intake()
 returns trigger
 language plpgsql
 security definer
 set search_path to ''
as $function$
begin
  if new.student_id is not null and new.intake_id is not null then
    insert into public.student_intakes (student_id, intake_id)
    values (new.student_id, new.intake_id)
    on conflict (student_id, intake_id) do nothing;
  end if;
  return new;
end $function$;
