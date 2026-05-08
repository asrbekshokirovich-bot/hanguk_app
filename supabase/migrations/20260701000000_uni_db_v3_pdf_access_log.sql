-- ============================================================================
--  uni_db v3 — pdf_access_log (audit table for signed-URL grants)
--
--  Plan §H.5 + ADR-009. The Phase 2 storage migration created the
--  `guideline-blobs` Supabase Storage bucket. Phase 3 adds the audit
--  trail: every signed-URL grant inserts a row here so we can detect
--  scraping or token leakage post-facto.
--
--  Writes happen exclusively via the `get-pdf-url` Edge Function (uses
--  the service role). Direct inserts from anon / authenticated clients
--  are blocked by RLS.
--
--  Reads:
--    - The user can SELECT their own audit rows (so the app can show
--      "you opened this PDF on Date X")
--    - uni_db_reviewer / uni_db_admin can SELECT all rows for HITL
--      anomaly detection
-- ============================================================================

create table if not exists public.pdf_access_log (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  document_id     uuid not null,             -- references public.documents(id) but
                                              -- omits the FK so log rows survive
                                              -- document soft-deletes for forensics
  bucket          text not null default 'guideline-blobs',
  object_path     text not null,
  granted_at      timestamptz not null default now(),
  expires_at      timestamptz not null,
  ip              inet,
  user_agent      text,
  reason          text                       -- optional: 'open_original',
                                              -- 'admin_review', 'export'
);

create index if not exists pdf_access_log_user_idx
  on public.pdf_access_log (user_id, granted_at desc);
create index if not exists pdf_access_log_document_idx
  on public.pdf_access_log (document_id, granted_at desc);

alter table public.pdf_access_log enable row level security;

drop policy if exists pdf_access_log_select_self on public.pdf_access_log;
create policy pdf_access_log_select_self on public.pdf_access_log
  for select using (auth.uid() = user_id);

drop policy if exists pdf_access_log_select_reviewer on public.pdf_access_log;
create policy pdf_access_log_select_reviewer on public.pdf_access_log
  for select using (
    coalesce(
      (select role from public.profiles where user_id = auth.uid()),
      'student'
    ) in ('uni_db_reviewer', 'uni_db_admin')
  );

-- INSERT is service-role only (no policy for app users).
-- Service role bypasses RLS by default, so the get-pdf-url Edge
-- Function can write freely.

comment on table public.pdf_access_log is
  'Audit log for signed-URL grants on guideline-blobs bucket. ADR-009.';
comment on column public.pdf_access_log.expires_at is
  'When the signed URL expires. 15 minutes after granted_at.';
