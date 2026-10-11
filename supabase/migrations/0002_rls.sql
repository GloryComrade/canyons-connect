-- Canyons Connect — Row-Level Security
-- Every table has RLS enabled. Users reach only their own rows; school-wide
-- content is read-only; integration secrets are unreachable from clients.

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;

create policy profiles_select_own on public.profiles
  for select using (auth.uid() = id);
create policy profiles_insert_own on public.profiles
  for insert with check (auth.uid() = id);
create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- Helper macro pattern: user-owned tables (select/insert/update/delete own)
-- ---------------------------------------------------------------------------
alter table public.class_periods enable row level security;
create policy class_periods_rw on public.class_periods
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.assignments enable row level security;
create policy assignments_rw on public.assignments
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.grades enable row level security;
create policy grades_rw on public.grades
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.notifications enable row level security;
create policy notifications_rw on public.notifications
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.club_memberships enable row level security;
create policy club_memberships_rw on public.club_memberships
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- events — own rows + school-wide (user_id is null) are readable
-- ---------------------------------------------------------------------------
alter table public.events enable row level security;
create policy events_select on public.events
  for select using (user_id is null or auth.uid() = user_id);
create policy events_insert_own on public.events
  for insert with check (auth.uid() = user_id);
create policy events_update_own on public.events
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy events_delete_own on public.events
  for delete using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- School-wide content — read-only to authenticated users
-- ---------------------------------------------------------------------------
alter table public.newsletters enable row level security;
create policy newsletters_read on public.newsletters
  for select using (auth.uid() is not null);

alter table public.news_items enable row level security;
create policy news_items_read on public.news_items
  for select using (auth.uid() is not null);

alter table public.clubs enable row level security;
create policy clubs_read on public.clubs
  for select using (auth.uid() is not null);

alter table public.photo_events enable row level security;
create policy photo_events_read on public.photo_events
  for select using (auth.uid() is not null);

-- ---------------------------------------------------------------------------
-- Photo Drop — photos scoped to event participants
-- ---------------------------------------------------------------------------
alter table public.photo_participants enable row level security;
create policy photo_participants_rw on public.photo_participants
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.photos enable row level security;
create policy photos_select_participant on public.photos
  for select using (
    exists (
      select 1 from public.photo_participants pp
      where pp.event_id = photos.event_id and pp.user_id = auth.uid()
    )
  );
create policy photos_insert_participant on public.photos
  for insert with check (
    auth.uid() = uploader_id and
    exists (
      select 1 from public.photo_participants pp
      where pp.event_id = photos.event_id and pp.user_id = auth.uid()
    )
  );
create policy photos_delete_own on public.photos
  for delete using (auth.uid() = uploader_id);

-- ---------------------------------------------------------------------------
-- Integrations — owner may read non-secret status; writes are server-side only
-- ---------------------------------------------------------------------------
alter table public.integrations enable row level security;
create policy integrations_select_own on public.integrations
  for select using (auth.uid() = user_id);
-- No insert/update/delete policy for clients: Edge Functions (service role)
-- manage integration rows. The service role bypasses RLS.

-- integration_secrets: RLS ON, NO policies → clients can never read or write.
-- Only the service role (Edge Functions) can touch tokens/credentials.
alter table public.integration_secrets enable row level security;
