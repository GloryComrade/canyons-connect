// Builds a provider OAuth authorize URL with a signed state param and returns
// it to the client, which opens it. Requires the caller's Supabase JWT.
import { corsHeaders, json } from "../_shared/cors.ts";
import { getUser } from "../_shared/client.ts";
import { oauthConfig, signState } from "../_shared/providers.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const user = await getUser(req);
  if (!user) return json({ error: "unauthorized" }, 401);

  const { provider } = await req.json().catch(() => ({}));
  const cfg = oauthConfig(provider);
  if (!cfg) return json({ error: `unknown or non-OAuth provider: ${provider}` }, 400);

  const redirectUri = `${Deno.env.get("SUPABASE_URL")}/functions/v1/oauth-callback`;
  const state = await signState(user.id, provider);

  const params = new URLSearchParams({
    client_id: cfg.clientId(),
    response_type: provider === "groupme" ? "token" : "code",
    redirect_uri: redirectUri,
    state,
  });
  if (cfg.scopes) params.set("scope", cfg.scopes);

  return json({ authorize_url: `${cfg.authorizeUrl}?${params.toString()}` });
});
