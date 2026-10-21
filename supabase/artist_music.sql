-- Run once in Supabase SQL Editor for Purple Hippo Music.
create table if not exists public.artist_tracks (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 title text not null check (char_length(trim(title)) between 1 and 120),
 storage_path text not null unique,
 created_at timestamptz not null default now()
);
-- Let PostgREST join tracks to their artist profiles.
do $ begin
 if not exists (select 1 from pg_constraint where conname='artist_tracks_profile_fk') then
  alter table public.artist_tracks add constraint artist_tracks_profile_fk
   foreign key (user_id) references public.artist_profiles(user_id) on delete cascade;
 end if;
end $;
create index if not exists artist_tracks_user_idx on public.artist_tracks(user_id);
alter table public.artist_tracks enable row level security;
grant select on public.artist_tracks to anon, authenticated;
grant insert, delete on public.artist_tracks to authenticated;
drop policy if exists "Listen to published artist tracks" on public.artist_tracks;
create policy "Listen to published artist tracks" on public.artist_tracks for select to anon, authenticated
 using (exists (select 1 from public.artist_profiles p where p.user_id=artist_tracks.user_id and p.is_published) or (select auth.uid())=user_id);
drop policy if exists "Upload own track details" on public.artist_tracks;
create policy "Upload own track details" on public.artist_tracks for insert to authenticated
 with check ((select auth.uid())=user_id and storage_path like user_id::text || '/%');
drop policy if exists "Delete own tracks" on public.artist_tracks;
create policy "Delete own tracks" on public.artist_tracks for delete to authenticated
 using ((select auth.uid())=user_id);
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
 values ('artist-music','artist-music',true,15728640,array['audio/mpeg'])
 on conflict (id) do update set public=true,file_size_limit=15728640,allowed_mime_types=array['audio/mpeg'];
drop policy if exists "Artists upload own MP3 files" on storage.objects;
create policy "Artists upload own MP3 files" on storage.objects for insert to authenticated
 with check (bucket_id='artist-music' and (storage.foldername(name))[1]=(select auth.uid())::text and lower(storage.extension(name))='mp3');
drop policy if exists "Artists delete own MP3 files" on storage.objects;
create policy "Artists delete own MP3 files" on storage.objects for delete to authenticated
 using (bucket_id='artist-music' and (storage.foldername(name))[1]=(select auth.uid())::text);
