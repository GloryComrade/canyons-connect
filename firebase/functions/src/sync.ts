// Per-provider sync. Pulls from each connected provider and upserts into
// Firestore under users/{uid}/... . Firestore listeners push to clients live.
import type { firestore } from "firebase-admin";
import { decryptJson } from "./crypto";
import { oauthConfig } from "./providers";
import { syncSkywardData, type SkywardCreds } from "./skyward";

type DB = firestore.Firestore;

interface Secret {
  access_token?: string;
  refresh_token?: string;
  encrypted_credentials?: string;
  expires_at?: string | null;
}

export async function syncProvider(db: DB, uid: string, provider: string) {
  const secretRef = db.doc(`integration_secrets/${uid}/providers/${provider}`);
  const secretSnap = await secretRef.get();
  const secret = (secretSnap.data() ?? {}) as Secret;

  switch (provider) {
    case "canvas":
      return syncCanvas(db, uid, secret, secretRef);
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

/** Refresh access token when expires_at is missing, past, or within 5 minutes. */
async function ensureCanvasToken(
  db: DB,
  uid: string,
  secret: Secret,
  secretRef: firestore.DocumentReference
): Promise<string> {
  if (!secret.access_token) throw new Error("no canvas token");

  const expiresAt = secret.expires_at ? Date.parse(secret.expires_at) : NaN;
  const knownExpiry = Number.isFinite(expiresAt);
  const nearOrPast = knownExpiry && expiresAt <= Date.now() + 5 * 60 * 1000;
  if (!nearOrPast) return secret.access_token;
  if (!secret.refresh_token) {
    if (knownExpiry && expiresAt <= Date.now()) {
      throw new Error("canvas token expired; reconnect required");
    }
    return secret.access_token;
  }

  const cfg = oauthConfig("canvas");
  if (!cfg?.tokenUrl) throw new Error("canvas oauth not configured");

  const res = await fetch(cfg.tokenUrl, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      client_id: cfg.clientId,
      client_secret: cfg.clientSecret,
      refresh_token: secret.refresh_token,
    }),
  });
  if (!res.ok) throw new Error(`canvas token refresh failed: ${res.status}`);

  const tok: any = await res.json();
  const accessToken: string | undefined = tok.access_token;
  if (!accessToken) throw new Error("canvas refresh returned no access_token");

  const expiresAtIso = tok.expires_in
    ? new Date(Date.now() + tok.expires_in * 1000).toISOString()
    : null;
  const refreshToken: string = tok.refresh_token ?? secret.refresh_token;

  await secretRef.set(
    {
      access_token: accessToken,
      refresh_token: refreshToken,
      expires_at: expiresAtIso,
      updated_at: new Date().toISOString(),
    },
    { merge: true }
  );
  await db.doc(`users/${uid}/integrations/canvas`).set(
    { expires_at: expiresAtIso },
    { merge: true }
  );

  return accessToken;
}

/** Follow Canvas Link: rel="next" pagination; falls back to a single page. */
async function canvasFetchAll<T>(
  url: string,
  headers: Record<string, string>
): Promise<T[]> {
  const out: T[] = [];
  let next: string | null = url;
  while (next) {
    const res: Response = await fetch(next, { headers });
    if (!res.ok) throw new Error(`canvas fetch failed: ${res.status} ${next}`);
    const page: unknown = await res.json();
    if (Array.isArray(page)) out.push(...(page as T[]));
    const link: string = res.headers.get("Link") ?? "";
    const m: RegExpMatchArray | null = link.match(/<([^>]+)>;\s*rel="next"/);
    next = m?.[1] ?? null;
  }
  return out;
}

function canvasSubmissionDone(submission: Record<string, unknown> | null | undefined): boolean {
  if (!submission) return false;
  const state = submission.workflow_state;
  if (state === "submitted" || state === "graded") return true;
  if (submission.submitted_at) return true;
  if (submission.excused === true) return true;
  return false;
}

// --- Canvas: REST API with the user's OAuth token ---
// Students complete work IN Canvas; sync maps submission state → hub status.
async function syncCanvas(
  db: DB,
  uid: string,
  secret: Secret,
  secretRef: firestore.DocumentReference
) {
  const token = await ensureCanvasToken(db, uid, secret, secretRef);
  const base = process.env.CANVAS_BASE_URL;
  if (!base) throw new Error("CANVAS_BASE_URL not set");
  const headers = { Authorization: `Bearer ${token}` };

  const courses = await canvasFetchAll<Record<string, unknown>>(
    `${base}/api/v1/courses?enrollment_state=active&per_page=50`,
    headers
  );

  const now = Date.now();
  const windowStart = now - 7 * 24 * 60 * 60 * 1000;
  const windowEnd = now + 30 * 24 * 60 * 60 * 1000;

  // Firestore batches max 500 ops; chunk if needed.
  let batch = db.batch();
  let ops = 0;
  const commitIfNeeded = async (force = false) => {
    if (ops === 0) return;
    if (!force && ops < 450) return;
    await batch.commit();
    batch = db.batch();
    ops = 0;
  };

  for (const course of courses) {
    if (course.id == null) continue;
    let assignments: Record<string, unknown>[] = [];
    try {
      assignments = await canvasFetchAll<Record<string, unknown>>(
        `${base}/api/v1/courses/${course.id}/assignments?include[]=submission&per_page=100`,
        headers
      );
    } catch {
      continue;
    }
    for (const a of assignments) {
      if (!a.due_at || typeof a.due_at !== "string") continue;
      const dueMs = Date.parse(a.due_at);
      if (!Number.isFinite(dueMs) || dueMs < windowStart || dueMs > windowEnd) continue;

      const submission = a.submission as Record<string, unknown> | undefined;
      const ref = db.doc(`users/${uid}/assignments/canvas_${a.id}`);
      batch.set(
        ref,
        {
          user_id: uid,
          source: "canvas",
          external_id: String(a.id),
          title: a.name,
          course: course.name,
          due_at: a.due_at,
          is_ib_task: false,
          url: a.html_url ?? null,
          status: canvasSubmissionDone(submission) ? "done" : "todo",
        },
        { merge: true }
      );
      ops += 1;
      await commitIfNeeded();
    }
  }
  await commitIfNeeded(true);
}

// --- Skyward: OneRoster REST (or SKYWARD_SYNC_FIXTURE demo data) ---
async function syncSkyward(db: DB, uid: string, encrypted?: string) {
  if (!encrypted) throw new Error("no skyward credentials");
  const creds = decryptJson(encrypted) as SkywardCreds;
  await syncSkywardData(db, uid, creds);
}

// --- ManageBac: API if available, else login/ICS ---
async function syncManageBac(db: DB, uid: string, encrypted?: string) {
  if (!encrypted) throw new Error("no managebac credentials");
  const _creds = decryptJson(encrypted);
  // TODO: upsert IB deadlines / IAs / CAS into users/{uid}/assignments
  //       with source='managebac', is_ib_task=true.
  void db;
  void uid;
  void _creds;
}

// --- GroupMe: groups + recent messages -> notifications ---
async function syncGroupMe(db: DB, uid: string, token?: string) {
  if (!token) throw new Error("no groupme token");
  // TODO: map new messages into users/{uid}/notifications (source='groupme').
  void db;
  void uid;
}
