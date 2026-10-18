// Per-provider sync. Pulls from each connected provider and upserts into
// Firestore under users/{uid}/... . Firestore listeners push to clients live.
import type { firestore } from "firebase-admin";
import { decryptJson } from "./crypto";

type DB = firestore.Firestore;

interface Secret {
  access_token?: string;
  refresh_token?: string;
  encrypted_credentials?: string;
}

export async function syncProvider(db: DB, uid: string, provider: string) {
  const secretSnap = await db.doc(`integration_secrets/${uid}/providers/${provider}`).get();
  const secret = (secretSnap.data() ?? {}) as Secret;

  switch (provider) {
    case "canvas":
      return syncCanvas(db, uid, secret.access_token);
    case "skyward":
      return syncSkyward(db, uid, secret.encrypted_credentials);
    case "managebac":
      return syncManageBac(db, uid, secret.encrypted_credentials);
    case "groupme":
      return syncGroupMe(db, uid, secret.access_token);
    default:
      return;
  }
}

// --- Canvas: REST API with the user's OAuth token ---
async function syncCanvas(db: DB, uid: string, token?: string) {
  if (!token) throw new Error("no canvas token");
  const base = process.env.CANVAS_BASE_URL;
  const headers = { Authorization: `Bearer ${token}` };

  const courses = (await fetch(
    `${base}/api/v1/courses?enrollment_state=active&per_page=50`,
    { headers }
  ).then((r) => r.json())) as any[];

  const batch = db.batch();
  for (const course of courses ?? []) {
    const assignments = (await fetch(
      `${base}/api/v1/courses/${course.id}/assignments?per_page=100`,
      { headers }
    )
      .then((r) => r.json())
      .catch(() => [])) as any[];
    for (const a of assignments ?? []) {
      if (!a.due_at) continue;
      const ref = db.doc(`users/${uid}/assignments/canvas_${a.id}`);
      batch.set(
        ref,
        {
          source: "canvas",
          external_id: String(a.id),
          title: a.name,
          course: course.name,
          due_at: a.due_at,
          is_ib_task: false,
          url: a.html_url ?? null,
        },
        { merge: true }
      );
    }
  }
  await batch.commit();
}

// --- Skyward: district API if granted, else login scrape ---
async function syncSkyward(db: DB, uid: string, encrypted?: string) {
  if (!encrypted) throw new Error("no skyward credentials");
  const _creds = decryptJson(encrypted);
  // TODO: fetch the class schedule -> users/{uid}/class_periods
  //       and current grades (NO GPA) -> users/{uid}/grades
  //       using district API access or an authenticated scrape with _creds.
  void _creds;
}

// --- ManageBac: API if available, else login/ICS ---
async function syncManageBac(db: DB, uid: string, encrypted?: string) {
  if (!encrypted) throw new Error("no managebac credentials");
  const _creds = decryptJson(encrypted);
  // TODO: upsert IB deadlines / IAs / CAS into users/{uid}/assignments
  //       with source='managebac', is_ib_task=true.
  void _creds;
}

// --- GroupMe: groups + recent messages -> notifications ---
async function syncGroupMe(db: DB, uid: string, token?: string) {
  if (!token) throw new Error("no groupme token");
  // TODO: map new messages into users/{uid}/notifications (source='groupme').
  void db;
  void uid;
}
