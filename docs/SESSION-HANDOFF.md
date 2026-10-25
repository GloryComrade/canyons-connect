# Canyons Connect — Session Handoff

_Last updated: 2026-10-25_

Read this first when picking the project up on another machine or in a new
session. It captures the full state, what's live, what's pending, the
environment gotchas, and the **two-computer GitHub sync workflow**.

---

## TL;DR — where things stand

- **What:** Canyons Connect — one unified app for Hillcrest High students
  (consolidates Canvas, Skyward, ManageBac, ParentSquare, GroupMe, Clubs, and
  The Utah View). **Flutter** (web/iOS/Android/macOS/Windows) + **Firebase**.
- **Repo:** https://github.com/GloryComrade/canyons-connect (private, `main`).
- **The whole app UI is built and runs today** in demo/mock mode — no backend
  needed. All screens, the Today dashboard, bell-schedule engine, design system.
- **Backend = Firebase**, project **`canyons-connect-dbd53c`**. Firestore DB +
  security rules are live. Auth providers, Storage, and Cloud Functions still
  need console/billing steps (see Pending).
- **Run the demo right now:**
  ```
  flutter run -d chrome --dart-define=USE_MOCK_DATA=true
  ```

---

## Architecture (why swapping backends was cheap)

The UI depends only on a single interface, `HubRepository`
(`lib/data/hub_repository.dart`). Two implementations:
- `MockRepository` — in-memory sample data (student "Maya Ramirez").
- `FirebaseRepository` — Cloud Firestore + Storage + Functions.

`AppConfig.useMockData` picks mock whenever Firebase isn't configured or
`USE_MOCK_DATA=true`. So **no screen code changes between demo and live**.

- State mgmt: **Riverpod**. Routing: **go_router** (auth guard +
  `StatefulShellRoute` over 8 tabs).
- Design system: `lib/design_system/` + `lib/core/theme/` (strict tokens; see
  `docs/DESIGN_SYSTEM.md`).
- Layout: `lib/core`, `lib/design_system`, `lib/models`, `lib/data`,
  `lib/features/<screen>`, `lib/shell`. Backend in `firebase/`.

> History note: the backend was first built on Supabase, then **migrated to
> Firebase** on request (commit `d0e03e0`). The Supabase code was removed; git
> history still has it if ever needed.

---

## What's been built (app)

- **Today dashboard**: live Now card (bell-schedule hero, 30s tick), Due Soon
  (Canvas+ManageBac merged, overdue-first, IB tags, done checkbox), Grades
  snapshot, Inbox feed w/ source filters, This Week strip, Utah View card, Quick
  actions. Subtle time-of-day re-ranking; pull-to-refresh.
- **Screens**: Schedule (bell + agenda, editable classes), Grades (Skyward of
  record, no GPA, expandable Canvas coursework), Inbox, Clubs (join/leave),
  Utah View (stories + newsletters), Photo Drop (+ event detail), Profile,
  Connections (OAuth + credential flows), global Search, Auth/onboarding.
- **Bell-schedule engine** (`lib/features/schedule/bell_schedule.dart`) — pure,
  unit-tested (regular/early-out/assembly/weekend/before/after).
- Verified repeatedly: `flutter analyze` clean, `flutter build web` succeeds.

---

## Backend: Firebase — what's LIVE vs PENDING

Project: **`canyons-connect-dbd53c`**
([console](https://console.firebase.google.com/project/canyons-connect-dbd53c/overview)).

### ✅ Done (provisioned from the CLI session)
- Project created; app registered for all 5 platforms (`flutterfire configure`
  → `lib/firebase_options.dart`, committed).
- Google Cloud APIs enabled: firestore, firebasestorage, storage, identitytoolkit.
- **Firestore database created** (`nam5`).
- **Firestore security rules + indexes deployed** (the RLS equivalent —
  `firebase/firestore.rules`, compiled clean).
- Client-side profile creation added (works even before Cloud Functions exist).

### ⏳ Pending (need the Firebase console / Blaze billing — only you can do)
1. **Enable a sign-in provider** — [Authentication → Get started](https://console.firebase.google.com/project/canyons-connect-dbd53c/authentication/providers)
   → turn on **Google** (and/or Email/Password). _Required before anyone can
   sign in live._ (The free tier can't enable this via API.)
2. **Upgrade to Blaze** (pay-as-you-go; has a free tier) — needed for Cloud
   Functions and the default Storage bucket.
3. **Enable Storage** — [Storage → Get started](https://console.firebase.google.com/project/canyons-connect-dbd53c/storage) (needs Blaze). Required for Photo Drop.
4. **Deploy Cloud Functions + seed content** — after Blaze:
   ```
   cd "<project>"
   firebase deploy --only functions --project canyons-connect-dbd53c
   # then seed school-wide content (clubs/news/calendar/photo events):
   BASE="https://us-central1-canyons-connect-dbd53c.cloudfunctions.net"
   curl "$BASE/seed?secret=$(grep ^SEED_SECRET firebase/functions/.env | cut -d= -f2)"
   ```
5. **Provider credentials** (Canvas/GroupMe/Skyward/ManageBac): fill in
   `firebase/functions/.env`, then re-`firebase deploy --only functions`.

### Sync implementation status
- **Canvas** sync (REST) is implemented in `firebase/functions/src/sync.ts`.
- Skyward / ManageBac / GroupMe / ParentSquare / Clubs are **scaffolded with the
  exact wiring + TODOs** — need provider credentials/approvals.

---

## How to run

```
cd "/Users/ryancheng/Downloads/the test code project "   # note the trailing space

# Demo (no backend, full sample data) — USE THIS to see the app:
flutter run -d chrome --dart-define=USE_MOCK_DATA=true

# Live (after enabling a sign-in provider in the console):
flutter run -d chrome
```

If the screen is blank: you're likely opening `build/web/index.html` directly
(don't — use `flutter run`), or an old instance is running (press `q`, re-run).
A `main()` change needs a full restart, not hot reload. Startup is hardened so a
stalled Firebase init can't blank the app (8s timeout → mock fallback).

---

## ⚠️ Environment gotchas (these bit us repeatedly)

1. **Folder name has spaces AND a trailing space**
   (`/Users/ryancheng/Downloads/the test code project `). Web/macOS/analyze are
   fine, but **Android Gradle builds fail with spaces** — for `flutter build
   apk`, clone into a space-free path like `~/dev/canyons-connect`. Always quote
   the path.
2. **Flaky local proxy** (privoxy `127.0.0.1:1087`, socks `:1086`) resets TLS to
   pub.dev / npm / GitHub. **Workaround:** prefix network commands with
   `env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy …`
   (used for `pub get`, `npm install`, `git push`, `firebase …`).
3. **Root-owned npm cache** (`~/.npm`) caused `EACCES`. Fix once:
   `sudo chown -R $(id -u):$(id -g) ~/.npm`.
4. **`flutter test` can't run here** — the test runner's loopback websocket is
   blocked (HTTP 500). Code is correct; verify logic via `dart run` or on a
   machine where the harness works. `flutter analyze` + `flutter build web` are
   the reliable checks in this environment.
5. No `gcloud`, no Docker installed. Firebase API enablement was done by minting
   a token from the Firebase CLI's stored session (scripts under scratch, not in
   repo).

---

## 🔁 Two-computer workflow (GitHub sync)

`main` is the single source of truth. Golden rule: **pull before you start,
commit + push before you stop.**

### Daily routine (each machine)
```
git pull --rebase origin main      # start of session
# …work…
git add -A && git commit -m "…"
git push origin main               # end of session (proxy? prefix with env -u …)
```
If a push rejects (the other machine pushed first):
`git pull --rebase origin main` then `git push`.

### First-time setup on a NEW computer
```
git clone https://github.com/GloryComrade/canyons-connect.git
cd canyons-connect
./scripts/bootstrap.sh             # flutter pub get + functions npm install
# sign in to Firebase on this machine (opens a browser):
firebase login
# regenerate the native Firebase config (or copy the files — see below):
flutterfire configure --project canyons-connect-dbd53c
# run the demo:
flutter run -d chrome --dart-define=USE_MOCK_DATA=true
```
Prereqs on each machine: Flutter SDK, Node 20+, `npm i -g firebase-tools`,
`dart pub global activate flutterfire_cli` (ensure `~/.pub-cache/bin` on PATH).

### Files that are NOT in git (must transfer or regenerate per machine)
These are gitignored on purpose (secrets / per-machine). `firebase_options.dart`
**is** committed and syncs automatically.

| File | How to get it on the other machine |
|------|-----------------------------------|
| `firebase/functions/.env` | **Copy it securely** (AirDrop / password manager). Contains `CREDENTIALS_ENC_KEY` — see warning below. |
| `android/app/google-services.json` | Regenerated by `flutterfire configure` (or copy). |
| `ios/Runner/GoogleService-Info.plist` | Regenerated by `flutterfire configure` (or copy). |
| `macos/Runner/GoogleService-Info.plist` | Regenerated by `flutterfire configure` (or copy). |

> **⚠️ CREDENTIALS_ENC_KEY must stay identical across machines** once any login
> credential has been encrypted/stored, or stored credentials become
> undecryptable. Nothing is encrypted yet (Functions not deployed), so you can
> regenerate for now — but the durable fix for two machines is to move the
> Function secrets to the cloud: `firebase functions:secrets:set CREDENTIALS_ENC_KEY`
> (and the others), so neither `.env` matters and both machines share them.

### What already syncs via git (nothing to do)
All source, `lib/firebase_options.dart`, Firestore/Storage rules, Cloud Function
source, scripts, and docs.

---

## Secrets & config reference

- **`firebase/functions/.env`** (gitignored): `CREDENTIALS_ENC_KEY`,
  `STATE_SIGNING_SECRET`, `SEED_SECRET`, `CANVAS_WEBHOOK_SECRET` (generated), plus
  blank provider id/secret fields to fill. Template: `firebase/functions/env.example`.
- **`lib/firebase_options.dart`** (committed): public Firebase client config —
  not a secret, safe in the repo.
- Firebase CLI login lives in `~/.config/configstore/firebase-tools.json`
  (per machine; do `firebase login` on each).

---

## Command cheat-sheet

```
# analyze / build (reliable here)
flutter analyze
flutter build web --no-tree-shake-icons

# functions build
cd firebase/functions && npm install && npm run build && cd -

# deploy rules (no Blaze needed)
firebase deploy --only firestore:rules,firestore:indexes --project canyons-connect-dbd53c

# deploy functions (needs Blaze)
firebase deploy --only functions --project canyons-connect-dbd53c

# everything network-y, if the proxy misbehaves:
env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY <command>
```

## Open next-steps (suggested order)
1. Enable Google sign-in in the console → live sign-in works.
2. Upgrade to Blaze → deploy Functions → `curl …/seed` → full live data.
3. Implement Skyward sync (schedule + grades) — the highest-value integration.
4. Wire `image_picker` for real Photo Drop uploads.
5. (Optional) point the Utah View tab at the real `api.theutahview.com`.
