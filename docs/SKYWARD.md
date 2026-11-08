# Skyward: getting real schedule and grades into Canyons Connect

_Last updated: 2026-11-08_

## What Canyons runs

- Canyons School District moved its student system from classic Skyward
  (SMS 2.0) to **Skyward Qmlativ**. Qmlativ Finance went live on 2025-10-26
  and **Qmlativ Student went live on 2026-07-20**
  ([district IT page](https://www.canyonsdistrict.org/depts/information-technology/qmlativ/),
  [announcement](https://www.canyonsdistrict.org/general-news/a-more-user-friendly-skyward-is-coming-this-summer/)).
- Students and families sign in through Family Access
  (`https://student.canyonsdistrict.org`) or the **Skyward Mobile Access** app.

## Ways in, and which one we use

| Path | Who can get it | Verdict |
|---|---|---|
| **District OneRoster 1.1 API** (Skyward API server, OAuth2 key + secret) | District IT grants it to an approved vendor/app | **Recommended.** Stable, documented, what Google Classroom, Microsoft SDS, etc. use. Code is ready (`oneroster.ts`). |
| Skyward's own partner API | Skyward-approved vendors, enabled by the district | Same approval path as OneRoster, more work. Not needed. |
| Logging in as the student (Family Access / mobile app) | Anyone with a student password | **Not built.** See "Why not log in as the student" below. |
| Manual export (PDF/print of schedule or report card) | Any student | Possible fallback for a one-time schedule import; not live grades. |

There is no student-facing API or personal access token in Skyward (unlike
Canvas), so a student can't get real Skyward data into the app on their own.
The district has to say yes.

## What's built (ready to plug in)

- `firebase/functions/src/oneroster.ts`: OneRoster 1.1 client.
  - OAuth2 client credentials (`SKYWARD_TOKEN_URL`, `SKYWARD_CLIENT_ID`,
    `SKYWARD_CLIENT_SECRET`), cached token, one retry on 401. A static
    `SKYWARD_API_KEY` bearer still works if that's what IT hands out.
  - Finds the student by sourcedId, student number (`identifier`), username,
    or (if no number entered) by their district email.
  - **Ownership check:** a district key can read every student, so the sync
    only accepts a record whose OneRoster email matches the signed-in user's
    verified email. Students must sign in with their district Google account.
  - Schedule from `/students/{id}/classes` + `/classes/{id}/teachers`, sorted
    by period. Grades from the gradebook service
    (`/classes/{c}/students/{s}/results` + `/lineItems/{id}`), preferring
    term/quarter grade line items. If the district only grants rostering, the
    schedule still syncs and grades are skipped.
- `skyward.ts` writes schedule/grades to Firestore as before, keeps rows the
  student edited, and now removes stale Skyward rows (e.g. leftover sample data).
- The background poll hits the real API at most every `SKYWARD_POLL_MINUTES`
  (default 60) per student. Pull-to-refresh is immediate.
- The Connect Skyward sheet no longer asks for a Skyward password.
- Tests: `cd firebase/functions && npm test` (fake Skyward server).
- Probe: once IT sends credentials, put them in `firebase/functions/.env` and run
  `npm run skyward:probe -- <student number>` to see exactly what would sync,
  before deploying. It never prints the secret.

## Turning it on once the district says yes

1. Put the values IT gives you in `firebase/functions/.env`:
   ```
   SKYWARD_API_BASE=https://<their host>/<path>          # root or .../ims/oneroster/v1p1
   SKYWARD_TOKEN_URL=https://<their host>/<token path>
   SKYWARD_CLIENT_ID=...
   SKYWARD_CLIENT_SECRET=...
   SKYWARD_SYNC_FIXTURE=0
   ```
   Better: `firebase functions:secrets:set SKYWARD_CLIENT_SECRET`.
2. `npm run skyward:probe -- <your student number>` and check the output.
3. `firebase deploy --only functions --project canyons-connect-dbd53c`.
4. In the app: Connections → Skyward → Disconnect, then Connect.

## Why not log in as the student

It's technically possible (the app would store each student's Skyward password
and replay the Family Access login), but:

- **District policy.** Canyons' acceptable-use rules and Utah's student data
  privacy law expect third parties that handle student records to have an
  agreement with the district. Automating a student login skips that and could
  get the account or the app blocked.
- **Fragile.** Qmlativ's web app is a JavaScript single-page app with session
  tokens and anti-automation measures; Skyward changes it without notice. A
  scraper breaks silently, and the mobile app's API is private and unsupported.
- **Security.** We'd be holding real student passwords for the district
  account, which usually also unlocks Google, Canvas, and email.
- **Terms.** Skyward's terms prohibit automated access outside its APIs.

If the district declines, a narrow fallback is a personal "import my schedule"
from a file the student downloads themselves. Ask before building that.

## The request to send

See [`SKYWARD-DISTRICT-REQUEST.md`](SKYWARD-DISTRICT-REQUEST.md).
