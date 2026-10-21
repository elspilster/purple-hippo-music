-- Purple Hippo Music: artist profiles v1
-- Run once in Supabase SQL Editor. Public profiles are opt-in.
create table if not exists public.artist_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  artist_name text not null check (char_length(trim(artist_name)) between 2 and 80),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  bio text not null default '' check (char_length(bio) <= 1000),
  genre text not null default '' check (char_length(genre) <= 80),
  website text not null default '' check (char_length(website) <= 300),
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.artist_profiles enable row level security;
revoke all on public.artist_profiles from anon, authenticated;
grant select on public.artist_profiles to anon, authenticated;
grant insert, update, delete on public.artist_profiles to authenticated;
drop policy if exists "Public sees published artists" on public.artist_profiles;
create policy "Public sees published artists" on public.artist_profiles
for select to anon, authenticated using (is_published or (select auth.uid()) = user_id);
drop policy if exists "Artist creates own profile" on public.artist_profiles;
create policy "Artist creates own profile" on public.artist_profiles
for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "Artist edits own profile" on public.artist_profiles;
create policy "Artist edits own profile" on public.artist_profiles
for update to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
drop policy if exists "Artist deletes own profile" on public.artist_profiles;
create policy "Artist deletes own profile" on public.artist_profiles
for delete to authenticated using ((select auth.uid()) = user_id);
