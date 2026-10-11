# Canyons Connect

One unified app for Hillcrest High School students — the single place to open
each morning to see your day, assignments, grades, schedule, clubs, photos, and
school news. It consolidates **Canvas, Skyward, ManageBac, ParentSquare,
GroupMe, the School Clubs site, and The Utah View** into one clean dashboard.

- **Frontend:** Flutter (one Dart codebase → Web, iOS, Android, Windows, macOS)
- **Backend:** Supabase (Postgres + Auth + Realtime + Storage + Edge Functions)
- **Repo:** https://github.com/GloryComrade/canyons-connect

> **Runs out of the box.** With no backend configured the app boots on an
> in-memory **mock data layer** (student "Maya Ramirez") so every screen is
> fully explorable. Add Supabase keys to switch to the live backend — no code
> changes.

---

## Quick start

```bash
flutter pub get

# Run in demo/mock mode (no backend needed):
flutter run -d chrome          # or: macos / windows / ios / android

# Run against a real Supabase project:
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<publishable-anon-key>
```

For many `--dart-define`s, put them in a JSON file and use
`--dart-define-from-file=env.json` (that file is gitignored).

### Build for each platform

```bash
flutter build web
flutter build apk           # Android (or appbundle for Play Store)
flutter build ios           # iOS (then archive in Xcode for the App Store)
flutter build macos         # macOS .app (sign & notarize to distribute)
flutter build windows       # Windows .exe (package with msix/Inno Setup)
```

> **Path note:** this checkout lives in a folder whose name contains spaces (and
> a trailing space). Web/macOS/analyze handle that fine, but the **Android
> Gradle build requires a path without spaces** — clone into e.g.
> `~/dev/canyons-connect` before `flutter build apk`.

---

## What's implemented

| Area | Status |
|------|--------|
| Design system (tokens, components, light/dark, WCAG AA) | ✅ Built to spec |
| Today dashboard (Now card, Due Soon, Grades, Inbox, This Week, Utah View, Quick actions) | ✅ |
| Bell schedule engine (live current period, countdown, special days) | ✅ unit-tested |
| Schedule, Grades, Inbox, Clubs, Utah View, Photo Drop, Profile, Connections, Search | ✅ |
| Auth (Google primary + email fallback) & routing with auth guard | ✅ |
| Data layer: repository interface + mock + Supabase (Realtime/Storage/Functions) | ✅ |
| Supabase schema + RLS + storage + Edge Functions | ✅ |
| Canvas sync (REST) | ✅ implemented in `sync-now` |
| Skyward / ManageBac / GroupMe / ParentSquare / Clubs sync | ⚙️ scaffolded with the exact wiring + TODOs (need provider credentials) |

### Needs your accounts/approvals to go fully live
These can't be provisioned from source alone; the wiring is in place for each:
- A Supabase project (URL + anon key, service-role key for functions)
- Canvas developer key (district Canvas admin)
- Skyward district API approval, or a test account for login-based sync
- GroupMe OAuth app; ManageBac API/ICS; ParentSquare & Clubs feed access
- Apple/Google/Microsoft developer accounts + signing certs for store submission

---

## Architecture

```
Flutter clients (web/iOS/Android/Windows/macOS)
        │  supabase_flutter: Auth · Postgres · Realtime · Storage
        ▼
Supabase project
  Postgres (RLS on every table)  ← system of record
  Realtime  → live Now card / Due Soon / Grades / Inbox / Clubs / Photos
  Storage   → Photo Drop (private, signed URLs)
  Edge Functions (service role) ← the ONLY holder of integration secrets
        │
        ▼
Canvas · Skyward · ManageBac · GroupMe · ParentSquare · Clubs · District site
```

- **`lib/core`** — config, theme/design-system tokens, router, utils
- **`lib/design_system`** — approved components (button, card, chip, segmented, …)
- **`lib/models`** — domain models mirroring the Postgres schema
- **`lib/data`** — `HubRepository` interface, `MockRepository`, `SupabaseRepository`, auth, Riverpod providers
- **`lib/features`** — one folder per screen/feature
- **`lib/shell`** — responsive navigation shell
- **`supabase/`** — migrations, RLS, storage, Edge Functions (see `supabase/README.md`)

State management is **Riverpod**; navigation is **go_router** with an auth
redirect and a `StatefulShellRoute` over the eight primary destinations.

### Mock vs. live
`AppConfig.useMockData` is true whenever Supabase isn't configured (or
`--dart-define=USE_MOCK_DATA=true`). The UI depends only on `HubRepository`, so
switching backends changes no screen code.

---

## Integrations & sync

Connect each app **once** from the Connections screen; the hub stores the
long-lived refresh token (OAuth) or encrypted credentials (login-based) and
refreshes access tokens server-side before each sync.

| Provider | Link method | Pulls |
|----------|-------------|-------|
| Canvas | OAuth2 (district developer key) | assignments, announcements, due dates |
| Skyward | District API if granted, else encrypted login sync | **class schedule**, current grades, attendance (no GPA) |
| ManageBac | API if available, else login / ICS | IB deadlines, IAs, CAS |
| GroupMe | OAuth2 | group messages → Inbox |
| ParentSquare | Feed/scrape | posts → Inbox |
| School Clubs | Feed/scrape | rosters, meetings, posts |

**Sync engine:** webhooks first (Canvas, GroupMe → instant); 1-minute scheduled
poll for the rest; pull-to-refresh calls `sync-now`; Realtime pushes every
change to all clients. Full secret/OAuth/credential setup is in
[`supabase/README.md`](supabase/README.md) and [`supabase/env.example`](supabase/env.example).

---

## Design system

Built to a strict token spec — see [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md):

- 8px spacing grid (4/8/16/24/32/48), type scale 14/16/20/24/32 at two weights
- One accent (`#2563EB` light / `#60A5FA` dark), flat fills, ≤4px radius, 0–2px
  shadows, no gradients/glass/pills
- Every text pair meets **WCAG AA (≥4.5:1)**; full light + dark token sets
- Components define all states (default/hover/focus/active/disabled/loading/
  empty/error) with visible keyboard focus rings

**Self-test:** *8px grid, 24px between sections, single blue accent #2563EB, 4px
radius, flat fills.*

---

## Testing & verification

```bash
flutter analyze        # clean
flutter test           # unit (bell schedule, date utils) + widget smoke test
```

Verified during development: `flutter analyze` clean, core-logic checks pass,
and `flutter build web` succeeds (Wasm-compatible).

---

## Source control

Private repo at **https://github.com/GloryComrade/canyons-connect**, committed
feature-by-feature (scaffold → design system/data → app UI → backend → docs).
Secrets, env files, and build artifacts are gitignored; **no keys are ever
committed**.
