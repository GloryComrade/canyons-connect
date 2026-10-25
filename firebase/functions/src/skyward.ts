// Skyward OneRoster REST client + schedule/grades mapping into Firestore.
// When SKYWARD_API_BASE is unset and SKYWARD_SYNC_FIXTURE=1, uses a local
// fixture so Schedule/Grades can be demoed without district credentials.
import type { firestore } from "firebase-admin";
import * as fs from "fs";
import * as path from "path";

type DB = firestore.Firestore;

export interface SkywardCreds {
  account?: string;
  secret?: string;
}

interface PeriodRow {
  period: string;
  period_index: number;
  class_name: string;
  room?: string | null;
  teacher?: string | null;
  day_type?: string;
}

interface GradeRow {
  course: string;
  term: string;
  grade: string;
  school_year: string;
  percent?: number | null;
  teacher?: string | null;
}

interface SkywardPayload {
  periods: PeriodRow[];
  grades: GradeRow[];
}

function fixtureEnabled(): boolean {
  return process.env.SKYWARD_SYNC_FIXTURE === "1" || process.env.SKYWARD_SYNC_FIXTURE === "true";
}

function loadFixture(): SkywardPayload {
  const candidates = [
    path.join(__dirname, "fixtures", "skyward_sample.json"),
    path.join(__dirname, "..", "src", "fixtures", "skyward_sample.json"),
  ];
  for (const p of candidates) {
    if (fs.existsSync(p)) {
      return JSON.parse(fs.readFileSync(p, "utf8")) as SkywardPayload;
    }
  }
  // Inline fallback if file missing from deploy bundle.
  return {
    periods: [
      { period: "1", period_index: 0, class_name: "AP Calculus BC", room: "214", teacher: "Ms. Chen" },
      { period: "2", period_index: 1, class_name: "AP Chemistry", room: "118", teacher: "Dr. Reyes" },
      { period: "3", period_index: 2, class_name: "AP English Lit", room: "231", teacher: "Mr. Hart" },
      { period: "4", period_index: 3, class_name: "US History", room: "105", teacher: "Ms. Okafor" },
      { period: "5", period_index: 4, class_name: "Spanish IV", room: "140", teacher: "Sr. Vargas" },
      { period: "6", period_index: 5, class_name: "Advisory", room: "120", teacher: "Ms. Carter" },
      { period: "7", period_index: 6, class_name: "PE / Athletics", room: "Gym", teacher: "Coach Lee" },
    ],
    grades: [
      { course: "AP Calculus BC", term: "Q1", grade: "A-", school_year: "2025-26", percent: 91.2, teacher: "Ms. Chen" },
      { course: "AP Chemistry", term: "Q1", grade: "B+", school_year: "2025-26", percent: 88.4, teacher: "Dr. Reyes" },
      { course: "AP English Lit", term: "Q1", grade: "A", school_year: "2025-26", percent: 94.0, teacher: "Mr. Hart" },
      { course: "US History", term: "Q1", grade: "A-", school_year: "2025-26", percent: 90.1, teacher: "Ms. Okafor" },
      { course: "Spanish IV", term: "Q1", grade: "B", school_year: "2025-26", percent: 84.5, teacher: "Sr. Vargas" },
    ],
  };
}

async function oneRosterFetch(url: string, headers: Record<string, string>): Promise<any> {
  const res = await fetch(url, { headers });
  if (!res.ok) throw new Error(`skyward fetch failed: ${res.status} ${url}`);
  return res.json();
}

/** Authenticate against district OneRoster (API key or basic). */
async function fetchFromApi(creds: SkywardCreds): Promise<SkywardPayload> {
  const base = (process.env.SKYWARD_API_BASE ?? "").replace(/\/$/, "");
  const apiKey = process.env.SKYWARD_API_KEY ?? "";
  if (!base) throw new Error("SKYWARD_API_BASE not set");

  const headers: Record<string, string> = {
    Accept: "application/json",
  };
  if (apiKey) {
    headers.Authorization = `Bearer ${apiKey}`;
  }

  const studentKey = (creds.account ?? "").trim();
  if (!studentKey) throw new Error("skyward student account required");

  // OneRoster 1.1 style paths (Qmlativ / SMS). Districts vary; adjust filters as needed.
  const students = await oneRosterFetch(
    `${base}/ims/oneroster/v1p1/students?filter=sourcedId='${encodeURIComponent(studentKey)}'%20OR%20identifier='${encodeURIComponent(studentKey)}'&limit=5`,
    headers
  ).catch(async () =>
    oneRosterFetch(`${base}/ims/oneroster/v1p1/students/${encodeURIComponent(studentKey)}`, headers)
  );

  const student =
    students?.user ??
    students?.student ??
    (Array.isArray(students?.users) ? students.users[0] : null) ??
    (Array.isArray(students) ? students[0] : students);
  const sourcedId = student?.sourcedId ?? student?.sourced_id ?? studentKey;
  if (!sourcedId) throw new Error("skyward student not found");

  const enrollmentsPayload = await oneRosterFetch(
    `${base}/ims/oneroster/v1p1/enrollments?filter=user.sourcedId='${encodeURIComponent(sourcedId)}'&limit=100`,
    headers
  ).catch(() =>
    oneRosterFetch(
      `${base}/ims/oneroster/v1p1/students/${encodeURIComponent(sourcedId)}/classes`,
      headers
    )
  );

  const enrollments: any[] =
    enrollmentsPayload?.enrollments ??
    enrollmentsPayload?.classes ??
    (Array.isArray(enrollmentsPayload) ? enrollmentsPayload : []);

  const periods: PeriodRow[] = [];
  const grades: GradeRow[] = [];
  const year = currentSchoolYear();
  let index = 0;

  for (const e of enrollments) {
    const classHref = e?.class?.href ?? e?.class?.sourcedId ?? e?.sourcedId;
    let cls = e?.class ?? e;
    if (typeof classHref === "string" && classHref.startsWith("http")) {
      cls = await oneRosterFetch(classHref, headers).catch(() => cls);
      cls = cls?.class ?? cls;
    } else if (typeof classHref === "string" && !cls?.title) {
      cls = await oneRosterFetch(
        `${base}/ims/oneroster/v1p1/classes/${encodeURIComponent(classHref)}`,
        headers
      ).catch(() => cls);
      cls = cls?.class ?? cls;
    }

    const className = cls?.title ?? cls?.classCode ?? cls?.name ?? `Class ${index + 1}`;
    const periodLabel =
      String(cls?.periods?.[0] ?? cls?.period ?? e?.metadata?.period ?? index + 1);
    const room = cls?.location ?? cls?.metadata?.room ?? null;
    const teacher =
      cls?.teachers?.[0]?.name ??
      cls?.metadata?.teacher ??
      e?.metadata?.teacher ??
      null;

    periods.push({
      period: periodLabel,
      period_index: index,
      class_name: className,
      room,
      teacher,
      day_type: "regular",
    });

    // Results / lineItems vary widely; try a common pattern then skip.
    const classId = cls?.sourcedId ?? classHref;
    if (classId && typeof classId === "string" && !classId.startsWith("http")) {
      const results = await oneRosterFetch(
        `${base}/ims/oneroster/v1p1/classes/${encodeURIComponent(classId)}/students/${encodeURIComponent(sourcedId)}/results`,
        headers
      ).catch(() => null);
      const list: any[] = results?.results ?? (Array.isArray(results) ? results : []);
      const latest = list[0];
      if (latest) {
        const score = latest.score != null ? Number(latest.score) : null;
        grades.push({
          course: className,
          term: latest.metadata?.term ?? "Current",
          grade: String(latest.scoreStatus ?? latest.metadata?.letter ?? letterFromPercent(score)),
          school_year: year,
          percent: score,
          teacher,
        });
      }
    }
    index += 1;
  }

  if (!periods.length) throw new Error("skyward returned no classes for student");
  return { periods, grades };
}

function currentSchoolYear(): string {
  const now = new Date();
  const y = now.getFullYear();
  const start = now.getMonth() >= 6 ? y : y - 1;
  return `${start}-${String(start + 1).slice(2)}`;
}

function letterFromPercent(p: number | null): string {
  if (p == null || Number.isNaN(p)) return "—";
  if (p >= 93) return "A";
  if (p >= 90) return "A-";
  if (p >= 87) return "B+";
  if (p >= 83) return "B";
  if (p >= 80) return "B-";
  if (p >= 77) return "C+";
  if (p >= 73) return "C";
  if (p >= 70) return "C-";
  if (p >= 60) return "D";
  return "F";
}

async function writeScheduleAndGrades(db: DB, uid: string, payload: SkywardPayload) {
  const periodsCol = db.collection(`users/${uid}/class_periods`);
  const gradesCol = db.collection(`users/${uid}/grades`);

  const existing = await periodsCol.get();
  const edited = new Set(
    existing.docs
      .filter((d: firestore.QueryDocumentSnapshot) => d.data()?.edited_by_user === true)
      .map((d: firestore.QueryDocumentSnapshot) => d.id)
  );

  let batch = db.batch();
  let ops = 0;
  const flush = async (force = false) => {
    if (ops === 0) return;
    if (!force && ops < 450) return;
    await batch.commit();
    batch = db.batch();
    ops = 0;
  };

  for (const p of payload.periods) {
    const id = `skyward_p${p.period_index}`;
    if (edited.has(id)) continue;
    batch.set(
      periodsCol.doc(id),
      {
        period: p.period,
        period_index: p.period_index,
        class_name: p.class_name,
        room: p.room ?? null,
        teacher: p.teacher ?? null,
        day_type: p.day_type ?? "regular",
        source: "skyward",
        edited_by_user: false,
        user_id: uid,
      },
      { merge: true }
    );
    ops += 1;
    await flush();
  }

  const now = new Date().toISOString();
  for (let i = 0; i < payload.grades.length; i++) {
    const g = payload.grades[i];
    const id = `skyward_g${i}_${slug(g.course)}`;
    batch.set(
      gradesCol.doc(id),
      {
        user_id: uid,
        course: g.course,
        term: g.term,
        grade: g.grade,
        school_year: g.school_year,
        percent: g.percent ?? null,
        teacher: g.teacher ?? null,
        updated_at: now,
      },
      { merge: true }
    );
    ops += 1;
    await flush();
  }
  await flush(true);
}

function slug(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "").slice(0, 40);
}

export async function syncSkywardData(db: DB, uid: string, creds: SkywardCreds) {
  const base = process.env.SKYWARD_API_BASE ?? "";
  let payload: SkywardPayload;
  if (!base && fixtureEnabled()) {
    payload = loadFixture();
  } else if (!base) {
    throw new Error("SKYWARD_API_BASE not set (set SKYWARD_SYNC_FIXTURE=1 for demo data)");
  } else {
    try {
      payload = await fetchFromApi(creds);
    } catch (e) {
      if (fixtureEnabled()) {
        payload = loadFixture();
      } else {
        throw e;
      }
    }
  }
  await writeScheduleAndGrades(db, uid, payload);
}
