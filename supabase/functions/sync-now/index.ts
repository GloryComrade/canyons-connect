// On-demand sync. Invoked by the client (pull-to-refresh, with the user's JWT)
// or internally after a connect (service role, with { user_id }). Pulls the
// latest from each connected provider and upserts into Postgres; Realtime then
// pushes changes to all clients.
import { corsHeaders, json } from "../_shared/cors.ts";
import { adminClient, getUser } from "../_shared/client.ts";
import { decryptJson } from "../_shared/crypto.ts";
import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const body = await req.json().catch(() => ({}));
  const user = await getUser(req);
  // Internal invocations (service role) pass user_id explicitly.
  const uid: string | undefined = user?.id ?? body.user_id;
  if (!uid) return json({ error: "unauthorized" }, 401);

  const onlyProvider: string | undefined = body.provider;
  const admin = adminClient();

  let q = admin.from("integrations").select("provider,status").eq("user_id", uid).eq("status", "connected");
  if (onlyProvider) q = q.eq("provider", onlyProvider);
  const { data: integrations } = await q;

  const results: Record<string, string> = {};
  for (const row of integrations ?? []) {
    try {
      await syncProvider(admin, uid, row.provider);
      await admin.from("integrations").update({ last_synced_at: new Date().toISOString() })
        .eq("user_id", uid).eq("provider", row.provider);
      results[row.provider] = "ok";
    } catch (e) {
      results[row.provider] = `error: ${e instanceof Error ? e.message : e}`;
      await admin.from("integrations").update({ status: "needs_reconnect" })
        .eq("user_id", uid).eq("provider", row.provider);
    }
  }

  return json({ synced: results });
});

async function loadSecret(admin: SupabaseClient, uid: string, provider: string) {
  const { data } = await admin.from("integration_secrets")
    .select("access_token,refresh_token,encrypted_credentials,expires_at")
    .eq("user_id", uid).eq("provider", provider).maybeSingle();
  return data;
}

async function syncProvider(admin: SupabaseClient, uid: string, provider: string) {
  const secret = await loadSecret(admin, uid, provider);
  switch (provider) {
    case "canvas":
      return await syncCanvas(admin, uid, secret?.access_token);
    case "skyward":
      return await syncSkyward(admin, uid, secret?.encrypted_credentials);
    case "managebac":
      return await syncManageBac(admin, uid, secret?.encrypted_credentials);
    case "groupme":
      return await syncGroupMe(admin, uid, secret?.access_token);
    // parentsquare / school_clubs are scrape/feed based (see sync-scheduled).
    default:
      return;
  }
}

// --- Canvas: REST API with the user's OAuth token ------------------------------
async function syncCanvas(admin: SupabaseClient, uid: string, token?: string | null) {
  if (!token) throw new Error("no canvas token");
  const base = Deno.env.get("CANVAS_BASE_URL");
  const headers = { Authorization: `Bearer ${token}` };

  const courses = await fetch(`${base}/api/v1/courses?enrollment_state=active&per_page=50`, { headers })
    .then((r) => r.json());

  const rows: Record<string, unknown>[] = [];
  for (const course of courses ?? []) {
    const assignments = await fetch(
      `${base}/api/v1/courses/${course.id}/assignments?per_page=100`,
      { headers },
    ).then((r) => r.json()).catch(() => []);
    for (const a of assignments ?? []) {
      if (!a.due_at) continue;
      rows.push({
        user_id: uid,
        source: "canvas",
        external_id: String(a.id),
        title: a.name,
        course: course.name,
        due_at: a.due_at,
        is_ib_task: false,
        url: a.html_url,
      });
    }
  }
  if (rows.length) {
    await admin.from("assignments").upsert(rows, { onConflict: "user_id,source,external_id" });
  }
  // Canvas announcements → notifications (left as a follow-up mapping).
}

// --- Skyward: district API if granted, else login-based scrape -----------------
async function syncSkyward(admin: SupabaseClient, uid: string, encrypted?: string | null) {
  if (!encrypted) throw new Error("no skyward credentials");
  const _creds = await decryptJson(encrypted);
  // TODO: with district-granted API access, fetch grades + schedule here.
  // Otherwise authenticate with _creds against Skyward and scrape:
  //   1. class schedule  -> upsert public.class_periods (period/class/room/teacher)
  //   2. current grades  -> upsert public.grades (NO GPA)
  //   3. attendance      -> (optional) notifications
  // Writes go through `admin` so RLS is bypassed server-side.
}

// --- ManageBac: API if available, else login/ICS -------------------------------
async function syncManageBac(admin: SupabaseClient, uid: string, encrypted?: string | null) {
  if (!encrypted) throw new Error("no managebac credentials");
  const _creds = await decryptJson(encrypted);
  // TODO: pull IB deadlines, Internal Assessments, CAS, unit plans ->
  // upsert into public.assignments with source='managebac', is_ib_task=true.
}

// --- GroupMe: list groups + recent messages -> notifications -------------------
async function syncGroupMe(admin: SupabaseClient, uid: string, token?: string | null) {
  if (!token) throw new Error("no groupme token");
  // const groups = await fetch(`https://api.groupme.com/v3/groups?token=${token}`)...
  // Map new messages into public.notifications (source='groupme').
}
