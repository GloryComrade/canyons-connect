// Skyward schedule/grades sync into Firestore.
// Real data comes from the district's OneRoster 1.1 API (see oneroster.ts and
// docs/SKYWARD.md). When SKYWARD_API_BASE is unset and SKYWARD_SYNC_FIXTURE=1,
// a local fixture is used so Schedule/Grades can be demoed without access.
import * as admin from "firebase-admin";
import type { firestore } from "firebase-admin";
import * as fs from "fs";
import * as path from "path";
import { OneRosterClient, configFromEnv, type SkywardPayload } from "./oneroster";

type DB = firestore.Firestore;

export interface SkywardCreds {
  account?: string;
  secret?: string;
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

  // Drop Skyward rows that this sync no longer returned (e.g. leftover sample
  // data after switching to the real API, or a dropped class). Rows the
  // student edited by hand are kept.
  const keepPeriods = new Set(payload.periods.map((p) => `skyward_p${p.period_index}`));
  for (const d of existing.docs) {
    if (d.id.startsWith("skyward_") && !keepPeriods.has(d.id) && !edited.has(d.id)) {
      batch.delete(d.ref);
      ops += 1;
      await flush();
    }
  }
  const keepGrades = new Set(payload.grades.map((g, i) => `skyward_g${i}_${slug(g.course)}`));
  const existingGrades = await gradesCol.get();
  for (const d of existingGrades.docs) {
    if (d.id.startsWith("skyward_") && !keepGrades.has(d.id)) {
      batch.delete(d.ref);
      ops += 1;
      await flush();
    }
  }
  await flush(true);
}

function slug(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "").slice(0, 40);
}

export async function syncSkywardData(db: DB, uid: string, creds: SkywardCreds) {
  const cfg = configFromEnv();
  let payload: SkywardPayload;
  if (!cfg && fixtureEnabled()) {
    payload = loadFixture();
  } else if (!cfg) {
    throw new Error("SKYWARD_API_BASE not set (set SKYWARD_SYNC_FIXTURE=1 for demo data)");
  } else {
    try {
      const user = await admin.auth().getUser(uid);
      if (!user.email || !user.emailVerified) {
        throw new Error("skyward: sign in with your verified district account first");
      }
      payload = await new OneRosterClient(cfg).fetchStudentData(creds.account ?? "", {
        expectedEmail: user.email,
      });
    } catch (e) {
      // Never paper over an ownership failure with sample data.
      if (!fixtureEnabled() || (e as { status?: number }).status === 403) throw e;
      console.warn("skyward: OneRoster failed, using fixture", (e as Error).message);
      payload = loadFixture();
    }
  }
  await writeScheduleAndGrades(db, uid, payload);
}
