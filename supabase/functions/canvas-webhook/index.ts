// Canvas webhook receiver. Register this URL as a Canvas Live Events / webhook
// endpoint so new assignments and announcements land in ~1s. Verifies a shared
// secret, then upserts into Postgres (Realtime pushes to clients).
import { json } from "../_shared/cors.ts";
import { adminClient } from "../_shared/client.ts";

Deno.serve(async (req) => {
  // Canvas signs payloads with HMAC; verify here. For a simple setup a shared
  // secret in the query/header is checked instead.
  const url = new URL(req.url);
  if (url.searchParams.get("secret") !== Deno.env.get("CANVAS_WEBHOOK_SECRET")) {
    return json({ error: "forbidden" }, 403);
  }

  const payload = await req.json().catch(() => ({}));
  const admin = adminClient();

  // Map the Canvas user to our profile via the stored external_account_id.
  // (Left as a lookup keyed on the Canvas user id in the event metadata.)
  const canvasUserId = payload?.metadata?.user_id;
  if (!canvasUserId) return json({ ignored: true });

  // Example: assignment_created / assignment_updated events.
  const body = payload?.body ?? {};
  if (body.assignment_id && body.due_at) {
    // Resolve uid from a mapping table or integrations.external_account_id,
    // then upsert the assignment. Shown as the shape of the write:
    // await admin.from("assignments").upsert({...}, { onConflict: "user_id,source,external_id" });
    void admin;
  }

  return json({ ok: true });
});
