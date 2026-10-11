# Going live with Supabase

The app already runs in demo mode (`flutter run -d chrome`). To connect the real
backend, do the two authenticated steps below — the rest is scripted.

What's already prepared for you:
- ✅ Supabase CLI installed (`supabase 2.120.0`)
- ✅ Server secrets generated in `supabase/.env` (gitignored): credential
  encryption key, OAuth state-signing secret, cron secret, Canvas webhook secret
- ✅ Migrations in Supabase timestamp format, ready for `db push`
- ✅ `scripts/setup_supabase.sh` — links/creates the project, pushes the schema,
  sets secrets, deploys functions, and writes `env.json`
- ✅ `scripts/run.sh` — runs the app against `env.json` (or mock mode if absent)

## Step 1 — authenticate the CLI (one time, opens a browser)

```bash
supabase login
```

## Step 2 — create/link the project and deploy everything

Create a brand-new project:

```bash
CREATE=1 scripts/setup_supabase.sh
# prints the project ref + generated DB password (save it) and finishes setup
```

**or** if you already made a project in the dashboard:

```bash
scripts/setup_supabase.sh <project-ref>
# optionally: SUPABASE_DB_PASSWORD=... scripts/setup_supabase.sh <project-ref>
```

This applies the schema + RLS + storage + seed, sets the Edge Function secrets,
deploys all seven functions, and writes `env.json` (SUPABASE_URL + anon key).

## Step 3 — enable Google sign-in (dashboard)

Auth → Providers → enable **Google** (and **Email**). Add redirect URLs:
- your web origin (e.g. `http://localhost:*` for dev)
- `canyonsconnect://login-callback` (mobile/desktop deep link)

(Create the Google OAuth client in Google Cloud Console; paste its client
id/secret into the Supabase Google provider.)

## Step 4 — run against the live backend

```bash
scripts/run.sh                 # chrome; uses env.json automatically
# or explicitly:
flutter run -d chrome --dart-define-from-file=env.json
```

Sign in with Google → a `profiles` row is created automatically → you land on
the Today dashboard. Until you connect Canvas/Skyward/etc. from the Connections
screen, those sections show their empty/connect states (schedule, grades, and
assignments populate after those syncs).

## Step 5 — enable the 1-minute sync cron

In the SQL editor, enable `pg_cron` + `pg_net` and schedule `sync-scheduled`
(see `supabase/README.md` for the exact `cron.schedule(...)` snippet using your
ref and `CRON_SECRET` from `supabase/.env`).

## Provider credentials (fill as you obtain them)

Add Canvas/GroupMe/Skyward/ManageBac values to `supabase/.env`, then re-push:

```bash
supabase secrets set --env-file supabase/.env   # (the script filters empties)
```

- **Canvas** — developer key from the district Canvas admin → `CANVAS_CLIENT_ID/SECRET`
- **GroupMe** — app at developers.groupme.com → `GROUPME_CLIENT_ID/SECRET`
- **Skyward** — district-granted API (`SKYWARD_API_*`) or students use login sync
- **ManageBac** — API token if the plan exposes one (`MANAGEBAC_API_*`)
```
