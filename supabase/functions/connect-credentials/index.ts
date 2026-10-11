// Stores login credentials for credential-based providers (Skyward, ManageBac,
// ParentSquare, School Clubs). Credentials are encrypted before storage and
// never returned to clients. Requires the caller's Supabase JWT.
import { corsHeaders, json } from "../_shared/cors.ts";
import { adminClient, getUser } from "../_shared/client.ts";
import { encryptJson } from "../_shared/crypto.ts";

const CREDENTIAL_PROVIDERS = new Set([
  "skyward",
  "managebac",
  "parentsquare",
  "school_clubs",
]);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const user = await getUser(req);
  if (!user) return json({ error: "unauthorized" }, 401);

  const { provider, credentials } = await req.json().catch(() => ({}));
  if (!CREDENTIAL_PROVIDERS.has(provider)) {
    return json({ error: `not a credential provider: ${provider}` }, 400);
  }
  if (!credentials || typeof credentials !== "object") {
    return json({ error: "missing credentials" }, 400);
  }

  const admin = adminClient();
  const ciphertext = await encryptJson(credentials);

  await admin.from("integration_secrets").upsert({
    user_id: user.id,
    provider,
    encrypted_credentials: ciphertext,
    updated_at: new Date().toISOString(),
  });

  const account = typeof credentials.account === "string" ? credentials.account : null;
  await admin.from("integrations").upsert({
    user_id: user.id,
    provider,
    status: "connected",
    external_account_id: account,
    last_synced_at: new Date().toISOString(),
  }, { onConflict: "user_id,provider" });

  // First sync (e.g. Skyward imports the class schedule + grades).
  admin.functions.invoke("sync-now", { body: { user_id: user.id, provider } }).catch(() => {});

  return json({ status: "connected" });
});
