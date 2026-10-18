# Going live with Firebase

The app already runs in demo mode (`flutter run -d chrome`). To connect the real
backend, do the authenticated steps below — the rest is scripted.

What's already prepared for you:
- ✅ Firebase packages wired (`firebase_core`, `firebase_auth`, `cloud_firestore`,
  `firebase_storage`, `cloud_functions`) and a `FirebaseRepository` behind the
  same `HubRepository` the UI uses
- ✅ Firestore Security Rules (the RLS equivalent), Storage rules, and Cloud
  Functions (auth trigger, OAuth, credential connect, sync, scheduler, webhook,
  seed) — **compiled and verified** (`tsc` clean)
- ✅ Function secrets generated in `firebase/functions/.env` (gitignored):
  credential-encryption key, OAuth state-signing secret, seed secret, Canvas
  webhook secret
- ✅ `scripts/setup_firebase.sh` — configures FlutterFire, builds + deploys
  everything; `scripts/run.sh` runs the app

## Step 0 — install the two CLIs (one time)

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli   # ensure ~/.pub-cache/bin is on PATH
```

## Step 1 — authenticate (one time, opens a browser)

```bash
firebase login
```

## Step 2 — configure + deploy everything

Use an existing project, or create one:

```bash
cd "/Users/ryancheng/Downloads/the test code project "
scripts/setup_firebase.sh <your-project-id>
# or create a new project first:
CREATE=1 scripts/setup_firebase.sh canyons-connect-<something-unique>
```

This runs `flutterfire configure` (writes `lib/firebase_options.dart` + platform
config), installs and builds the functions, and deploys Firestore rules, Storage
rules, and all Cloud Functions.

## Step 3 — finish in the Firebase console

- **Authentication → Sign-in method →** enable **Google** (and Email/Password).
- If prompted, **create the Firestore database** (production mode) and the
  default **Storage bucket**.
- **Seed school content** (clubs, news, newsletters, calendar, photo events):
  ```bash
  BASE="https://us-central1-<your-project-id>.cloudfunctions.net"
  curl "$BASE/seed?secret=$(grep ^SEED_SECRET firebase/functions/.env | cut -d= -f2)"
  ```

## Step 4 — run against the live backend

```bash
flutter run -d chrome        # or scripts/run.sh
```

Sign in with Google → the `onUserCreate` function creates your profile → you land
on the Today dashboard. Schedule, grades, and assignments populate once you
connect Canvas/Skyward/etc. from the Connections screen.

## Provider credentials (fill as you obtain them)

Add Canvas/GroupMe/Skyward/ManageBac values to `firebase/functions/.env`, then
redeploy the functions:

```bash
firebase deploy --only functions
```

- **Canvas** — developer key from the district Canvas admin → `CANVAS_CLIENT_ID/SECRET`
- **GroupMe** — app at developers.groupme.com → `GROUPME_CLIENT_ID/SECRET`
- **Skyward** — district-granted API (`SKYWARD_API_*`) or students use login sync
- **ManageBac** — API token if the plan exposes one (`MANAGEBAC_API_*`)

> For production, prefer `firebase functions:secrets:set <NAME>` over `.env` for
> the client secrets.

## Scheduled sync (every 1 minute)

The `syncScheduled` function is deployed with an `every 1 minutes` Pub/Sub
schedule automatically — no extra cron setup. (Scheduled functions require the
Blaze plan.)
