-- Canyons Connect — core schema
-- Postgres (Supabase). Row-level security is enabled in 0002_rls.sql.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Enums (values match the Dart model `db` strings exactly)
-- ---------------------------------------------------------------------------
create type assignment_source   as enum ('canvas', 'managebac');
create type assignment_status   as enum ('todo', 'done');
create type event_source        as enum ('canvas', 'managebac', 'school_site', 'club');
create type notification_source as enum ('parentsquare', 'groupme', 'canvas', 'skyward', 'clubs', 'school');
create type news_kind           as enum ('article', 'video');
create type membership_status   as enum ('joined', 'interested');
create type integration_provider as enum ('canvas', 'skyward', 'managebac', 'groupme', 'parentsquare', 'school_clubs', 'utah_view');
create type integration_status  as enum ('connected', 'not_connected', 'needs_reconnect', 'syncing', 'error');

-- ---------------------------------------------------------------------------
-- profiles — one row per user
-- ---------------------------------------------------------------------------
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  name        text not null default 'Student',
  grade       int,
  is_ib       boolean not null default false,
  avatar_url  text,
  email       text,
  settings    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- class_periods — the student's schedule (auto-imported from Skyward)
-- ---------------------------------------------------------------------------
create table public.class_periods (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles (id) on delete cascade,
  period        text not null,
  period_index  int  not null default 0,
  class_name    text not null,
  room          text,
  teacher       text,
  day_type      text not null default 'regular',
  source        text not null default 'skyward',
  edited_by_user boolean not null default false,
  created_at    timestamptz not null default now()
);
create index on public.class_periods (user_id, period_index);

-- ---------------------------------------------------------------------------
-- assignments — merged Canvas + ManageBac tasks
-- ---------------------------------------------------------------------------
create table public.assignments (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  source      assignment_source not null,
  external_id text,
  title       text not null,
  course      text not null default '',
  due_at      timestamptz not null,
  status      assignment_status not null default 'todo',
  is_ib_task  boolean not null default false,
  url         text,
  created_at  timestamptz not null default now(),
  unique (user_id, source, external_id)
);
create index on public.assignments (user_id, due_at);

-- ---------------------------------------------------------------------------
-- grades — Skyward grades of record (NO GPA stored)
-- ---------------------------------------------------------------------------
create table public.grades (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles (id) on delete cascade,
  course           text not null,
  term             text not null default '',
  grade            text not null default '',
  percent          numeric(5,2),
  previous_percent numeric(5,2),
  school_year      text not null default '',
  teacher          text,
  updated_at       timestamptz not null default now(),
  unique (user_id, course, term, school_year)
);
create index on public.grades (user_id);

-- ---------------------------------------------------------------------------
-- events — unified calendar (user-scoped OR school-wide when user_id is null)
-- ---------------------------------------------------------------------------
create table public.events (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid references public.profiles (id) on delete cascade,
  source    event_source not null,
  title     text not null,
  starts_at timestamptz not null,
  ends_at   timestamptz,
  type      text not null default 'event',
  location  text,
  all_day   boolean not null default false,
  url       text,
  club_id   uuid,
  created_at timestamptz not null default now()
);
create index on public.events (user_id, starts_at);
create index on public.events (starts_at) where user_id is null;

-- ---------------------------------------------------------------------------
-- notifications — the unified Inbox
-- ---------------------------------------------------------------------------
create table public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  source      notification_source not null,
  title       text not null,
  body        text,
  url         text,
  is_urgent   boolean not null default false,
  read_at     timestamptz,
  sender_name text,
  created_at  timestamptz not null default now()
);
create index on public.notifications (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- School-wide content (read-only to users)
-- ---------------------------------------------------------------------------
create table public.newsletters (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  teaser       text,
  body         text,
  published_at timestamptz not null default now(),
  external_url text
);

create table public.news_items (
  id               uuid primary key default gen_random_uuid(),
  title            text not null,
  kind             news_kind not null default 'article',
  body             text,
  media_url        text,
  published_at     timestamptz not null default now(),
  external_url     text,
  category         text,
  author           text,
  duration_seconds int
);

create table public.clubs (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  category     text not null default 'General',
  description  text,
  meeting_info text,
  cover_url    text,
  member_count int,
  advisor      text
);

create table public.club_memberships (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid not null references public.profiles (id) on delete cascade,
  club_id   uuid not null references public.clubs (id) on delete cascade,
  status    membership_status not null default 'interested',
  joined_at timestamptz not null default now(),
  unique (user_id, club_id)
);
create index on public.club_memberships (user_id);

-- ---------------------------------------------------------------------------
-- Photo Drop
-- ---------------------------------------------------------------------------
create table public.photo_events (
  id                uuid primary key default gen_random_uuid(),
  title             text not null,
  subtitle          text,
  starts_at         timestamptz not null default now(),
  cover_url         text,
  photo_count       int not null default 0,
  contributor_count int not null default 0,
  is_live           boolean not null default false
);

create table public.photo_participants (
  event_id  uuid not null references public.photo_events (id) on delete cascade,
  user_id   uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

create table public.photos (
  id           uuid primary key default gen_random_uuid(),
  event_id     uuid not null references public.photo_events (id) on delete cascade,
  uploader_id  uuid not null references public.profiles (id) on delete cascade,
  storage_path text not null,
  caption      text,
  created_at   timestamptz not null default now()
);
create index on public.photos (event_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Integrations — non-secret status (readable by owner). Secrets live apart.
-- ---------------------------------------------------------------------------
create table public.integrations (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references public.profiles (id) on delete cascade,
  provider            integration_provider not null,
  status              integration_status not null default 'not_connected',
  external_account_id text,
  expires_at          timestamptz,
  last_synced_at      timestamptz,
  detail              text,
  created_at          timestamptz not null default now(),
  unique (user_id, provider)
);
create index on public.integrations (user_id);

-- Secrets table: tokens + encrypted credentials. NO client RLS policy is ever
-- created for this table, so only Edge Functions (service role) can read it.
create table public.integration_secrets (
  user_id               uuid not null references public.profiles (id) on delete cascade,
  provider              integration_provider not null,
  access_token          text,
  refresh_token         text,
  encrypted_credentials text,   -- ciphertext (see Supabase Vault / pgsodium)
  expires_at            timestamptz,
  updated_at            timestamptz not null default now(),
  primary key (user_id, provider)
);

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

-- Create a profile row on sign-up and route the user into setup.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name',
             new.raw_user_meta_data->>'name',
             split_part(coalesce(new.email, 'Student'), '@', 1)),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep photo_events counts accurate as photos come and go.
create or replace function public.refresh_photo_counts(target uuid)
returns void language sql as $$
  update public.photo_events pe set
    photo_count = (select count(*) from public.photos where event_id = target),
    contributor_count = (select count(distinct uploader_id) from public.photos where event_id = target)
  where pe.id = target;
$$;

create or replace function public.on_photo_change()
returns trigger language plpgsql as $$
begin
  perform public.refresh_photo_counts(coalesce(new.event_id, old.event_id));
  return null;
end; $$;

drop trigger if exists photos_count_trigger on public.photos;
create trigger photos_count_trigger
  after insert or delete on public.photos
  for each row execute function public.on_photo_change();
