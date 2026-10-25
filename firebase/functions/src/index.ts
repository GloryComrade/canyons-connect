import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

import { encryptJson } from "./crypto";
import { oauthConfig, signState, verifyState } from "./providers";
import { syncProvider } from "./sync";

admin.initializeApp();
const db = admin.firestore();

const OAUTH_PROVIDERS = new Set(["canvas", "groupme"]);
const CREDENTIAL_PROVIDERS = new Set(["skyward", "managebac", "parentsquare", "school_clubs"]);
const POLL_PROVIDERS = ["skyward", "managebac", "parentsquare", "school_clubs"];

function callbackUrl(): string {
  return `${process.env.FUNCTIONS_BASE_URL}/oauthCallback`;
}

async function markStatus(uid: string, provider: string, patch: Record<string, unknown>) {
  await db.doc(`users/${uid}/integrations/${provider}`).set(
    { provider, ...patch },
    { merge: true }
  );
}

// ---------------------------------------------------------------------------
// Create a profile row on sign-up and route the student into setup.
// ---------------------------------------------------------------------------
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  await db.doc(`users/${user.uid}`).set(
    {
      name: user.displayName || (user.email ? user.email.split("@")[0] : "Student"),
      email: user.email ?? null,
      avatar_url: user.photoURL ?? null,
      is_ib: false,
      settings: {},
      created_at: new Date().toISOString(),
    },
    { merge: true }
  );
});

// ---------------------------------------------------------------------------
// OAuth: start → returns an authorize URL the client opens.
// ---------------------------------------------------------------------------
export const oauthStart = functions.https.onCall((data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError("unauthenticated", "sign in required");
  const provider = String(data?.provider ?? "");
  if (!OAUTH_PROVIDERS.has(provider)) {
    throw new functions.https.HttpsError("invalid-argument", `not an OAuth provider: ${provider}`);
  }
  const cfg = oauthConfig(provider)!;
  const params = new URLSearchParams({
    client_id: cfg.clientId,
    response_type: provider === "groupme" ? "token" : "code",
    redirect_uri: callbackUrl(),
    state: signState(uid, provider),
  });
  if (cfg.scopes) params.set("scope", cfg.scopes);
  return { authorize_url: `${cfg.authorizeUrl}?${params.toString()}` };
});

// ---------------------------------------------------------------------------
// OAuth: callback → exchange code, store encrypted tokens, mark connected.
// ---------------------------------------------------------------------------
export const oauthCallback = functions.https.onRequest(async (req, res) => {
  const state = String(req.query.state ?? "");
  const verified = verifyState(state);
  const appReturn = process.env.APP_OAUTH_RETURN_URL ?? "canyonsconnect://login-callback";
  if (!verified) {
    res.status(400).send("invalid state");
    return;
  }
  const { uid, provider } = verified;
  const cfg = oauthConfig(provider);
  if (!cfg) {
    res.status(400).send("unknown provider");
    return;
  }

  try {
    let accessToken: string | null = null;
    let refreshToken: string | null = null;
    let expiresAt: string | null = null;

    if (provider === "groupme") {
      accessToken = String(req.query.access_token ?? "") || null;
    } else {
      const code = String(req.query.code ?? "");
      if (!code) throw new Error("missing code");
      const resp = await fetch(cfg.tokenUrl, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "authorization_code",
          client_id: cfg.clientId,
          client_secret: cfg.clientSecret,
          redirect_uri: callbackUrl(),
          code,
        }),
      });
      if (!resp.ok) throw new Error(`token exchange failed: ${resp.status}`);
      const tok: any = await resp.json();
      accessToken = tok.access_token ?? null;
      refreshToken = tok.refresh_token ?? null;
      if (tok.expires_in) {
        expiresAt = new Date(Date.now() + tok.expires_in * 1000).toISOString();
      }
    }
    if (!accessToken) throw new Error("no access token");

    await db.doc(`integration_secrets/${uid}/providers/${provider}`).set({
      access_token: accessToken,
      refresh_token: refreshToken,
      expires_at: expiresAt,
      updated_at: new Date().toISOString(),
    });
    await markStatus(uid, provider, {
      status: "connected",
      expires_at: expiresAt,
      last_synced_at: new Date().toISOString(),
    });
    syncProvider(db, uid, provider).catch(() => {});

    res.redirect(`${appReturn}?connected=1&provider=${provider}`);
  } catch (_e) {
    await markStatus(uid, provider, { status: "error" });
    res.redirect(`${appReturn}?connected=0&provider=${provider}`);
  }
});

// ---------------------------------------------------------------------------
// Credential-based connect (Skyward, ManageBac, ParentSquare, Clubs).
// ---------------------------------------------------------------------------
export const connectCredentials = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError("unauthenticated", "sign in required");
  const provider = String(data?.provider ?? "");
  if (!CREDENTIAL_PROVIDERS.has(provider)) {
    throw new functions.https.HttpsError("invalid-argument", `not a credential provider: ${provider}`);
  }
  const credentials = data?.credentials ?? {};

  await db.doc(`integration_secrets/${uid}/providers/${provider}`).set({
    encrypted_credentials: encryptJson(credentials),
    updated_at: new Date().toISOString(),
  });
  await markStatus(uid, provider, {
    status: "connected",
    external_account_id: typeof credentials.account === "string" ? credentials.account : null,
    last_synced_at: new Date().toISOString(),
  });
  syncProvider(db, uid, provider).catch(() => {});
  return { status: "connected" };
});

// ---------------------------------------------------------------------------
// Disconnect: remove secrets, mark not connected.
// ---------------------------------------------------------------------------
export const disconnectIntegration = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError("unauthenticated", "sign in required");
  const provider = String(data?.provider ?? "");
  await db.doc(`integration_secrets/${uid}/providers/${provider}`).delete().catch(() => {});
  await markStatus(uid, provider, {
    status: "not_connected",
    external_account_id: null,
    expires_at: null,
  });
  return { status: "not_connected" };
});

// ---------------------------------------------------------------------------
// On-demand sync (pull-to-refresh / post-connect).
// ---------------------------------------------------------------------------
export const syncNow = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError("unauthenticated", "sign in required");
  const only = data?.provider ? String(data.provider) : null;

  const snap = await db.collection(`users/${uid}/integrations`).where("status", "==", "connected").get();
  const results: Record<string, string> = {};
  for (const doc of snap.docs) {
    const provider = doc.id;
    if (only && provider !== only) continue;
    try {
      await syncProvider(db, uid, provider);
      await markStatus(uid, provider, { last_synced_at: new Date().toISOString() });
      results[provider] = "ok";
    } catch (e) {
      results[provider] = `error`;
      await markStatus(uid, provider, { status: "needs_reconnect" });
    }
  }
  return { synced: results };
});

// ---------------------------------------------------------------------------
// Scheduled poll (every 1 minute) for providers without webhooks.
// ---------------------------------------------------------------------------
export const syncScheduled = functions.pubsub.schedule("every 1 minutes").onRun(async () => {
  const snap = await db
    .collectionGroup("integrations")
    .where("status", "==", "connected")
    .get();
  for (const doc of snap.docs) {
    const provider = doc.id;
    if (!POLL_PROVIDERS.includes(provider)) continue;
    const uid = doc.ref.parent.parent?.id;
    if (!uid) continue;
    try {
      await syncProvider(db, uid, provider);
      await markStatus(uid, provider, { last_synced_at: new Date().toISOString() });
    } catch (_e) {
      await markStatus(uid, provider, { status: "needs_reconnect" });
    }
  }
  // TODO: refresh school-wide calendar/news from the district site here too.
  return null;
});

// ---------------------------------------------------------------------------
// Club cover: joined members upload to Storage, then this sets clubs.cover_url.
// ---------------------------------------------------------------------------
export const setClubCover = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError("unauthenticated", "sign in required");
  const clubId = String(data?.clubId ?? "");
  const storagePath = String(data?.storagePath ?? "");
  if (!clubId || !storagePath.startsWith(`club-assets/${clubId}/`)) {
    throw new functions.https.HttpsError("invalid-argument", "clubId and storagePath required");
  }

  const membership = await db.doc(`users/${uid}/memberships/${clubId}`).get();
  if (!membership.exists || membership.data()?.status !== "joined") {
    throw new functions.https.HttpsError("permission-denied", "join the club to set its cover");
  }

  const bucket = admin.storage().bucket();
  const file = bucket.file(storagePath);
  const [exists] = await file.exists();
  if (!exists) {
    throw new functions.https.HttpsError("not-found", "uploaded file not found");
  }

  // Prefer a long-lived token URL so clients can load without signed-URL expiry churn.
  await file.makePublic().catch(() => {});
  const publicUrl = `https://storage.googleapis.com/${bucket.name}/${storagePath}`;

  await db.doc(`clubs/${clubId}`).set(
    { cover_url: publicUrl, cover_updated_at: new Date().toISOString(), cover_updated_by: uid },
    { merge: true }
  );
  return { cover_url: publicUrl };
});

// ---------------------------------------------------------------------------
// Canvas webhook (near-instant updates). Verify a shared secret.
// ---------------------------------------------------------------------------
export const canvasWebhook = functions.https.onRequest(async (req, res) => {
  if (req.query.secret !== process.env.CANVAS_WEBHOOK_SECRET) {
    res.status(403).send("forbidden");
    return;
  }
  // Map the Canvas user to a uid (via stored external_account_id), then upsert
  // the changed assignment/announcement. Shape left as a follow-up.
  res.json({ ok: true });
});

// ---------------------------------------------------------------------------
// One-time seed of school-wide content. Guard with ?secret=SEED_SECRET.
// ---------------------------------------------------------------------------
export const seed = functions.https.onRequest(async (req, res) => {
  if (req.query.secret !== process.env.SEED_SECRET) {
    res.status(403).send("forbidden");
    return;
  }
  const now = Date.now();
  const iso = (msAgo: number) => new Date(now - msAgo).toISOString();
  const day = (addDays: number, h = 0) =>
    new Date(new Date().setHours(0, 0, 0, 0) + addDays * 864e5 + h * 36e5).toISOString();

  const batch = db.batch();
  const clubs = [
    ["Robotics Team", "STEM", "Design, build, and compete with the Hillcrest robotics team.", "Tue & Thu · 3:30 PM · Rm 212", 28, "Dr. Reyes"],
    ["Ultimate Frisbee", "Sports", "Casual and competitive ultimate for all skill levels.", "Mon & Wed · 4:00 PM · Lower field", 19, "Coach Lee"],
    ["Orange Club", "Service", "Service projects and community volunteering.", "Fri · 12:45 PM · Rm 140", 34, "Ms. Okafor"],
    ["Drama Club", "Arts", "Stagecraft, acting, and the fall & spring productions.", "Mon–Thu · 3:30 PM · Auditorium", 41, "Mr. Hart"],
    ["Student Council", "Leadership", "Plan school events and represent the student body.", "Wed · 3:30 PM · Rm 120", 22, "Ms. Okafor"],
    ["Science Olympiad", "STEM", "Compete across 23 science & engineering events.", "Thu · 3:30 PM · Rm 214", 17, "Dr. Reyes"],
    ["Model UN", "Academic", "Debate global issues and travel to conferences.", "Tue · 3:30 PM · Rm 231", 15, "Mr. Dawson"],
    ["Key Club", "Service", "The largest student-led service organization.", "Fri · 3:30 PM · Rm 108", 30, "Ms. Carter"],
  ];
  for (const [name, category, description, meeting_info, member_count, advisor] of clubs) {
    batch.set(db.collection("clubs").doc(), { name, category, description, meeting_info, member_count, advisor });
  }

  const news = [
    ["Inside Canyons' new robotics lab", "video", "STEM", "Student Media", 184, iso(5 * 36e5)],
    ["Block schedule, one year in: what's working", "article", "School", "J. Alvarez", null, iso(864e5)],
    ["Cedar Canyon edges Alta 21–17 in season opener", "article", "Sports", "Husky Sports Desk", null, iso(2 * 864e5)],
    ["What Canyons students think of the IB Diploma", "video", "Academics", "Student Media", 263, iso(3 * 864e5)],
    ["Meet the seniors running \"Our Town\" this fall", "article", "Arts", "A. Chen", null, iso(4 * 864e5)],
  ];
  for (const [title, kind, category, author, duration_seconds, published_at] of news) {
    batch.set(db.collection("news_items").doc(), { title, kind, category, author, duration_seconds, published_at });
  }

  batch.set(db.collection("newsletters").doc(), {
    title: "The Husky Weekly — Week of Oct 6",
    teaser: "Homecoming spirit week, new robotics lab opens, and fall sports standings.",
    published_at: iso(2 * 864e5),
  });

  const events = [
    ["Early-out day", "early_out", day(1, 13)],
    ["PSAT testing", "test", day(3, 8)],
    ["No school — Teacher PD", "holiday", day(7)],
  ];
  for (const [title, type, starts_at] of events) {
    batch.set(db.collection("school_events").doc(), { source: "school_site", title, type, starts_at });
  }

  const photoEvents = [
    ["Friday Night Lights vs. Corner Canyon", "Varsity football · Home", 128, 42, true, day(0, 19)],
    ["Homecoming 2026", "Dance & spirit week", 86, 30, false, iso(7 * 864e5)],
    ["Robotics Regionals", "Competition day", 54, 12, false, iso(14 * 864e5)],
    ["Fall Play — Our Town", "Opening night", 33, 9, false, iso(21 * 864e5)],
  ];
  for (const [title, subtitle, photo_count, contributor_count, is_live, starts_at] of photoEvents) {
    batch.set(db.collection("photo_events").doc(), { title, subtitle, photo_count, contributor_count, is_live, starts_at });
  }

  await batch.commit();
  res.json({ seeded: true });
});
