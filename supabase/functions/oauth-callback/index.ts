// OAuth redirect target. Verifies the signed state, exchanges the auth code for
// tokens server-side (using the provider client secret), stores them encrypted,
// marks the integration connected, then deep-links back into the app.
import { adminClient } from "../_shared/client.ts";
import { oauthConfig, verifyState } from "../_shared/providers.ts";

const APP_REDIRECT = () =>
  Deno.env.get("APP_OAUTH_RETURN_URL") ?? "canyonsconnect://login-callback";

function redirectToApp(ok: boolean, provider: string): Response {
  const url = `${APP_REDIRECT()}?connected=${ok ? "1" : "0"}&provider=${provider}`;
  return new Response(null, { status: 302, headers: { Location: url } });
}

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const state = url.searchParams.get("state") ?? "";
  const verified = await verifyState(state);
  if (!verified) return new Response("invalid state", { status: 400 });

  const { uid, provider } = verified;
  const cfg = oauthConfig(provider);
  if (!cfg) return new Response("unknown provider", { status: 400 });

  const admin = adminClient();
  try {
    let accessToken: string | null = null;
    let refreshToken: string | null = null;
    let expiresAt: string | null = null;

    if (provider === "groupme") {
      // GroupMe returns the token directly on the redirect.
      accessToken = url.searchParams.get("access_token");
    } else {
      // Standard authorization-code exchange (Canvas).
      const code = url.searchParams.get("code");
      if (!code) throw new Error("missing code");
      const redirectUri = `${Deno.env.get("SUPABASE_URL")}/functions/v1/oauth-callback`;
      const res = await fetch(cfg.tokenUrl, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          grant_type: "authorization_code",
          client_id: cfg.clientId(),
          client_secret: cfg.clientSecret(),
          redirect_uri: redirectUri,
          code,
        }),
      });
      if (!res.ok) throw new Error(`token exchange failed: ${res.status}`);
      const tok = await res.json();
      accessToken = tok.access_token ?? null;
      refreshToken = tok.refresh_token ?? null;
      if (tok.expires_in) {
        expiresAt = new Date(Date.now() + tok.expires_in * 1000).toISOString();
      }
    }

    if (!accessToken) throw new Error("no access token");

    await admin.from("integration_secrets").upsert({
      user_id: uid,
      provider,
      access_token: accessToken,
      refresh_token: refreshToken,
      expires_at: expiresAt,
      updated_at: new Date().toISOString(),
    });

    await admin.from("integrations").upsert({
      user_id: uid,
      provider,
      status: "connected",
      expires_at: expiresAt,
      last_synced_at: new Date().toISOString(),
    }, { onConflict: "user_id,provider" });

    // Kick an initial sync (fire-and-forget).
    admin.functions.invoke("sync-now", { body: { user_id: uid, provider } }).catch(() => {});

    return redirectToApp(true, provider);
  } catch (_e) {
    await admin.from("integrations").upsert({
      user_id: uid,
      provider,
      status: "error",
    }, { onConflict: "user_id,provider" });
    return redirectToApp(false, provider);
  }
});
