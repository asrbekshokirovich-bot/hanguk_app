-- ============================================================================
--  TEMPORARY STAGING BASELINE
-- ============================================================================
--
-- Plan §I-Phase-0 step 1 calls for a full `supabase db dump` of production
-- as the migration floor. That dump requires Docker (Supabase CLI runs
-- pg_dump in a versioned container) or a native pg_dump install — neither
-- of which is available in the current session.
--
-- This file is a STAND-IN: it creates only the public.profiles table
-- that the uni_db v1 migrations' RLS policies and reviewer-assignment
-- helpers reference. Everything else our migrations create from scratch.
--
-- TO COMPLETE before any production deployment:
--   1. From a host with Docker (or native pg_dump 17.x) installed:
--        supabase db dump --linked --schema public \
--          > supabase/migrations/00000000000001_lovable_baseline.sql
--   2. Sanitize: strip ALTER OWNER, COMMENT ON ROLE, session-only SETs.
--   3. Replace this file's contents (keep the filename).
--
-- Until step 3, applying these migrations to PRODUCTION will skip the
-- profiles-creation block (idempotent IF NOT EXISTS) and rely on the
-- existing prod profiles table. Applying them to a fresh STAGING project
-- gives the minimum schema needed to satisfy FK / RLS dependencies.
-- ============================================================================

set local search_path = public, pg_catalog;

create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- ----------------------------------------------------------------------------
--  public.profiles  (minimal shim — production has more columns; this is
--  enough for the uni_db RLS policies + fn_pick_next_reviewer)
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  role       text not null default 'student'
             check (role in ('student','counselor','admin','uni_db_reviewer')),
  full_name  text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_role_idx on public.profiles (role);

alter table public.profiles enable row level security;

drop policy if exists profiles_self_read on public.profiles;
create policy profiles_self_read on public.profiles
  for select using (user_id = auth.uid());

drop policy if exists profiles_self_upsert on public.profiles;
create policy profiles_self_upsert on public.profiles
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());
