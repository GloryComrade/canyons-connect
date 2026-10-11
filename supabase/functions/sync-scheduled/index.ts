// Scheduled poll for providers without webhooks (Skyward, ManageBac, the
// school website calendar, the School Clubs site). Invoke from Supabase's
// scheduled functions / pg_cron every 1 minute (don't poll faster — rate
// limits & cost). Protected by a shared CRON_SECRET header.
import { json } from "../_shared/cors.ts";
import { adminClient } from "../_shared/client.ts";

const POLL_PROVIDERS = ["skyward", "managebac", "parentsquare", "school_clubs"];

Deno.serve(async (req) => {
  const secret = req.headers.get("x-cron-secret");
  if (secret !== Deno.env.get("CRON_SECRET")) {
    return json({ error: "forbidden" }, 403);
  }

  const admin = adminClient();

  // 1) Refresh per-user poll-based integrations.
  const { data: rows } = await admin
    .from("integrations")
    .select("user_id,provider")
    .eq("status", "connected")
    .in("provider", POLL_PROVIDERS);

  const byUser = new Map<string, string[]>();
  for (const r of rows ?? []) {
    byUser.set(r.user_id, [...(byUser.get(r.user_id) ?? []), r.provider]);
  }
  for (const [uid, providers] of byUser) {
    for (const provider of providers) {
      admin.functions.invoke("sync-now", { body: { user_id: uid, provider } }).catch(() => {});
    }
  }

  // 2) Refresh school-wide content (calendar / news / clubs) from the district
  //    site. These write school-wide rows (user_id null) via the service role.
  await refreshSchoolCalendar(admin);

  return json({ scheduled: (rows ?? []).length });
});

async function refreshSchoolCalendar(_admin: unknown) {
  // TODO: fetch the Hillcrest / Canyons District ICS or RSS feed and upsert
  // holidays, early-outs, testing days, and announcements into public.events
  // (source='school_site', user_id=null). Also refresh news_items / newsletters.
}
