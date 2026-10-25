# Canyons Connect — Firebase backend

Cloud Firestore + Auth + Storage + Cloud Functions. One project serves all five
client platforms. **No integration secret ever lives in the client** — OAuth
client secrets and login credentials live in Cloud Functions config /
`integration_secrets` and are used server-side only.

## Layout

```
firebase.json                 # (repo root) rules + functions + emulators config
firebase/
  firestore.rules             # per-collection security (the RLS equivalent)
  firestore.indexes.json      # (single-field orderBy only → no composites)
  storage.rules               # photo-drops bucket rules
  functions/
    env.example               # secrets template → copy to .env (gitignored)
    src/
      index.ts                # all functions (auth trigger, OAuth, connect,
                              #   disconnect, syncNow, syncScheduled, webhook, seed)
      providers.ts            # OAuth config + signed-state helpers
      crypto.ts               # AES-256-GCM credential encryption
      sync.ts                 # per-provider sync (Canvas + Skyward)
      skyward.ts              # OneRoster client + fixture schedule/grades
      fixtures/               # skyward_sample.json (when SKYWARD_SYNC_FIXTURE=1)
```

## Integrations notes

- **Canvas (no developer key):** students can paste a Canvas personal access token (Account → Settings → New Access Token). The `connectCanvasToken` callable checks it against `/api/v1/users/self`, stores it in `integration_secrets`, and syncs right away. Uses `CANVAS_BASE_URL`; when the token expires, the integration flips to `needs_reconnect`.
- **Canvas:** `syncCanvas` pulls assignments with `include[]=submission`, maps submitted/graded/excused → `status: done|todo`, writes `users/{uid}/assignments/canvas_*`. Students open work in Canvas; the hub mirrors LMS completion.
- **Skyward:** `syncSkywardData` uses OneRoster when `SKYWARD_API_BASE` is set; otherwise set `SKYWARD_SYNC_FIXTURE=1` for demo periods/grades. Respects `edited_by_user` on class periods.
- **Club covers (Canva):** client uploads to `club-assets/{clubId}/…`, then callable `setClubCover` verifies `memberships/{clubId}.status == joined` and sets `clubs/{id}.cover_url`.

## Data model (Firestore)

```
users/{uid}                         # profile (name, grade, is_ib, settings…)
users/{uid}/class_periods/{id}      # Skyward-imported schedule
users/{uid}/assignments/{id}        # Canvas + ManageBac (doc id: canvas_<id>)
users/{uid}/grades/{id}             # Skyward grades of record (no GPA)
users/{uid}/events/{id}             # personal calendar
users/{uid}/notifications/{id}      # Inbox
users/{uid}/memberships/{clubId}    # club join/interested
users/{uid}/integrations/{provider} # NON-secret connection status

clubs/{id}  news_items/{id}  newsletters/{id}  school_events/{id}   # school-wide
photo_events/{id}                   # Photo Drop event
photo_events/{id}/participants/{uid}
photo_events/{id}/photos/{photoId}

integration_secrets/{uid}/providers/{provider}   # tokens/creds — server only
```

## Setup

```bash
# Install CLIs
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Authenticate + configure + deploy (one command; see ../SETUP.md)
firebase login
../scripts/setup_firebase.sh <your-project-id>
```

The script runs `flutterfire configure` (generates `lib/firebase_options.dart`),
builds the functions, and deploys rules + functions.

### Secrets

`firebase/functions/.env` (gitignored) holds the generated encryption/signing
keys plus provider client ids/secrets. `firebase-functions` loads `.env` at
deploy. For production, prefer:

```bash
firebase functions:secrets:set CANVAS_CLIENT_SECRET
```

### Authentication (Google primary)

Console → **Authentication → Sign-in method** → enable **Google** (schools run
Workspace) and **Email/Password**. A `users/{uid}` profile is created
automatically by the `onUserCreate` trigger.

## Security model

- **Security Rules on every collection.** `users/{uid}/**` is owner-only.
  School-wide collections are read-only to signed-in users. Photo Drop photos
  are readable/writable only by event participants.
- **Secrets isolated.** `users/{uid}/integrations/{provider}` holds only
  non-secret status. Tokens and encrypted credentials live in
  `integration_secrets/**`, which the rules **deny to all clients** — only Cloud
  Functions (Admin SDK) can read them.
- **Connect-once.** Refresh tokens / encrypted credentials are stored
  server-side; access tokens refresh before each sync, so students never
  re-authenticate unless a token is revoked.

## Sync engine

- **Webhook:** `canvasWebhook` (register as a Canvas Live Events endpoint).
- **Scheduled:** `syncScheduled` runs `every 1 minutes` (Pub/Sub) for Skyward,
  ManageBac, ParentSquare, and the Clubs site. (Blaze plan required.)
- **On-demand:** pull-to-refresh calls the `syncNow` callable.
- **Live to clients:** Firestore snapshot listeners update the UI in ~1s.

## Local development (emulators)

```bash
cd firebase/functions && npm install && npm run build
firebase emulators:start   # auth, firestore, functions, storage + UI
```
