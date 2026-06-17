-- Track C (Phase 8 hardening): two uni_db SECURITY DEFINER helpers were
-- EXECUTE-able by the anon (unauthenticated) role —
--   fn_flag_source_wrong : report a source as wrong (abuse vector if left open)
--   fn_can_review_uni_db  : reviewer-permission check
-- The reviewer UI calls them as an authenticated user, so anon never needs
-- them. Revoke anon; keep authenticated (service_role retains it as before).
-- A future applicant-facing "report error" must be an authenticated action.
--
-- The reviewer's own actions (fn_review_accept/reject/edit_accept) were already
-- anon-locked + authenticated-granted, so the live reviewer is unaffected.
revoke execute on function public.fn_flag_source_wrong(uuid, text, uuid) from anon;
grant  execute on function public.fn_flag_source_wrong(uuid, text, uuid) to authenticated;

revoke execute on function public.fn_can_review_uni_db(uuid) from anon;
grant  execute on function public.fn_can_review_uni_db(uuid) to authenticated;
