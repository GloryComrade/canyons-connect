// Disconnects a provider: deletes stored secrets and marks the integration not
// connected. (Optionally revoke the token with the provider first.)
import { corsHeaders, json } from "../_shared/cors.ts";
import { adminClient, getUser } from "../_shared/client.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const user = await getUser(req);
  if (!user) return json({ error: "unauthorized" }, 401);

  const { provider } = await req.json().catch(() => ({}));
  if (!provider) return json({ error: "missing provider" }, 400);

  const admin = adminClient();

  // TODO: best-effort token revocation with the provider before deletion.

  await admin.from("integration_secrets")
    .delete()
    .eq("user_id", user.id)
    .eq("provider", provider);

  await admin.from("integrations").update({
    status: "not_connected",
    external_account_id: null,
    expires_at: null,
  }).eq("user_id", user.id).eq("provider", provider);

  return json({ status: "not_connected" });
});
