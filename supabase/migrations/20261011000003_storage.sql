-- Canyons Connect — Storage for Photo Drop
-- Private bucket; objects are keyed as "<event_id>/<file>". Access is scoped to
-- participants of that event, mirroring the photos-table RLS. The client reads
-- images via short-lived signed URLs.

insert into storage.buckets (id, name, public)
values ('photo-drops', 'photo-drops', false)
on conflict (id) do nothing;

-- Read objects only for events you've joined.
create policy "photo_drops_read_participant"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'photo-drops'
    and exists (
      select 1 from public.photo_participants pp
      where pp.user_id = auth.uid()
        and pp.event_id::text = (storage.foldername(name))[1]
    )
  );

-- Upload only into events you've joined.
create policy "photo_drops_insert_participant"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'photo-drops'
    and exists (
      select 1 from public.photo_participants pp
      where pp.user_id = auth.uid()
        and pp.event_id::text = (storage.foldername(name))[1]
    )
  );

-- Owners may remove their own uploads (object owner = uploader).
create policy "photo_drops_delete_own"
  on storage.objects for delete to authenticated
  using (bucket_id = 'photo-drops' and owner = auth.uid());
