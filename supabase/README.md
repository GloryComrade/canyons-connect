# Canyons Connect — Supabase backend

Postgres + Auth + Realtime + Storage + Edge Functions. One project serves all
five client platforms. **No integration secret ever lives in the client** — all
OAuth client secrets and login credentials live in Edge Function secrets /
Vault and are used server-side only.

## Layout

```
supabase/
  config.toml                 # CLI config (per-function verify_jwt)
  env.example                 # secrets template → copy to .env (gitignored)
  migrations/                 # timestamped; applied in order by `db push`
    20261011000001_schema.sql           # enums, tables, triggers
    20261011000002_rls.sql              # row-level security on every table
    20261011000003_storage.sql          # private photo-drops bucket + policies
    20261011000004_seed_schoolwide.sql  # shared content (clubs, news, calendar)
  functions/
    _shared/                  # cors, admin client, crypto, provider config
    oauth-start/              # builds provider authorize URL (signed state)
    oauth-callback/           # code→token exchange, stores encrypted tokens
    connect-credentials/      # stores encrypted login creds (Skyward, etc.)
    disconnect-integration/   # removes secrets, marks not connected
    sync-now/                 # on-demand + post-connect sync (per provider)
    sync-scheduled/           # 1-min cron poll for non-webhook providers
    canvas-webhook/           # instant Canvas updates
```

## One-time setup

```bash
# 1. Create a project at supabase.com, then link it:
supabase link --project-ref <your-ref>

# 2. Push the schema, RLS, storage, and seed:
supabase db push

# 3. Configure secrets (fill supabase/.env from env.example first):
cp supabase/env.example supabase/.env   # then edit
supabase secrets set --env-file supabase/.env

# 4. Deploy the Edge Functions:
supabase functions deploy oauth-start oauth-callback connect-credentials \
  disconnect-integration sync-now sync-scheduled canvas-webhook
```

## Authentication (Google primary)

In **Auth → Providers**, enable **Google** (schools run Workspace) and
**Email**. Add redirect URLs for every platform:

- Web: `https://<your-web-host>` and `http://localhost:*` for dev
- Mobile/desktop deep link: `canyonsconnect://login-callback`

A `profiles` row is created automatically on sign-up (trigger
`on_auth_user_created`).

## Scheduled sync (every 1 minute)

Enable `pg_cron` + `pg_net` (Database → Extensions), then:

```sql
select cron.schedule('canyons-sync', '* * * * *', $$
  select net.http_post(
    url     := 'https://<your-ref>.functions.supabase.co/sync-scheduled',
    headers := jsonb_build_object('x-cron-secret', '<CRON_SECRET>',
                                  'Content-Type', 'application/json'),
    body    := '{}'::jsonb
  );
$$);
```

Do **not** poll faster than 1 minute (rate limits + cost). Canvas and GroupMe
use webhooks for near-instant updates instead.

## Security model

- **RLS on every table.** Users select/insert/update only rows where
  `user_id = auth.uid()`. School-wide tables (newsletters, news_items, clubs,
  school events) are read-only to authenticated users. Photo Drop rows are
  scoped to event participants.
- **Secrets are isolated.** `integrations` holds only non-secret status columns
  (owner-readable). Tokens and encrypted credentials live in
  `integration_secrets`, which has **no client policy** — only the service role
  (Edge Functions) can read it.
- **Connect-once.** Long-lived refresh tokens / encrypted credentials are stored
  server-side and access tokens are refreshed before each sync, so students
  never re-authenticate unless a token is revoked.

## Local development

```bash
supabase start           # local stack
supabase db reset        # apply migrations + seed to the local db
supabase functions serve # run functions locally
```
