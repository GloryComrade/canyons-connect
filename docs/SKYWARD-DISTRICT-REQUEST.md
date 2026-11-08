# Request: read-only OneRoster access for a student-built app

Send to Canyons School District Information Technology (help desk / Student
Information Systems team). CC a teacher or administrator sponsor at Hillcrest
if you have one: a staff sponsor makes this much more likely to move forward.
Edit the bracketed parts.

---

**Subject:** Request for read-only OneRoster (Skyward Qmlativ) access for a Hillcrest student app

Hello,

My name is [Ryan Cheng], a [grade] student at Hillcrest High. I'm building
**Canyons Connect**, an app that puts a student's schedule, grades, Canvas
assignments, and school news in one place. [Teacher/admin name] is
sponsoring the project.

I'd like to ask whether the district would grant the app **read-only access
to the Skyward Qmlativ OneRoster 1.1 API**, the same kind of access the
district gives to tools like Google Classroom and Canvas. Specifically:

- **Rostering service (required):** students, classes, enrollments, teachers,
  academic sessions. This gives each student their own class schedule.
- **Gradebook service (optional):** results and line items for term/quarter
  grades. If the district prefers, we can start with schedules only.
- **Scope:** Hillcrest High students only is fine, or even a pilot with a
  small group of students who opt in.

How the app protects student data:

- Students sign in with their **district Google account**. The app only
  shows a student the record whose district email matches their sign-in.
- Data is stored in a Google Firebase project with per-student security
  rules; no other student, and no advertiser, can read it. Nothing is sold or
  shared.
- The app **never asks for or stores Skyward passwords**.
- The API key would be kept in Google Cloud Secret Manager, never in the app
  or in source code. The district can revoke it at any time.
- Access is read-only, and background syncs are limited to about once an hour
  per student.

I understand Utah law and district policy may require a data privacy
agreement or a review before any outside app can receive student data. I'm
happy to complete whatever forms, security review, or agreement are needed,
or to meet with someone to show how the app works.

If OneRoster access isn't possible, could you let me know whether there's
another approved way (for example, a student-initiated export) for an app
like this to read a student's own schedule?

Thank you for your time,
[Ryan Cheng]
[Hillcrest High, grade]
[district email]

---

## If they say yes, ask them for

1. The OneRoster base URL (e.g. `https://.../ims/oneroster/v1p1`).
2. The OAuth2 token URL, client ID, and client secret, sent securely (not
   plain email if possible).
3. Which services are enabled (rostering only, or gradebook too).
4. Whether the student `email` field is populated in OneRoster (the app uses
   it to match students to their sign-in).
