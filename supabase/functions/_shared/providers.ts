// OAuth provider configuration + signed-state helpers.
// Secrets (client id/secret, base URLs) are read from function secrets, never
// shipped to clients.

export interface OAuthProviderConfig {
  authorizeUrl: string;
  tokenUrl: string;
  clientId: () => string;
  clientSecret: () => string;
  scopes: string;
}

export function oauthConfig(provider: string): OAuthProviderConfig | null {
  switch (provider) {
    case "canvas": {
      const base = Deno.env.get("CANVAS_BASE_URL") ?? "";
      return {
        authorizeUrl: `${base}/login/oauth2/auth`,
        tokenUrl: `${base}/login/oauth2/token`,
        clientId: () => Deno.env.get("CANVAS_CLIENT_ID") ?? "",
        clientSecret: () => Deno.env.get("CANVAS_CLIENT_SECRET") ?? "",
        // Canvas uses granular "url:" scopes; configure per developer key.
        scopes: "url:GET|/api/v1/courses url:GET|/api/v1/announcements " +
          "url:GET|/api/v1/users/self/assignments url:GET|/api/v1/calendar_events",
      };
    }
    case "groupme":
      return {
        authorizeUrl: "https://oauth.groupme.com/oauth/authorize",
        tokenUrl: "", // GroupMe returns an access_token on the redirect itself
        clientId: () => Deno.env.get("GROUPME_CLIENT_ID") ?? "",
        clientSecret: () => Deno.env.get("GROUPME_CLIENT_SECRET") ?? "",
        scopes: "",
      };
    default:
      return null;
  }
}

const enc = new TextEncoder();

async function hmacKey(): Promise<CryptoKey> {
  const secret = Deno.env.get("STATE_SIGNING_SECRET") ?? "";
  return await crypto.subtle.importKey(
    "raw",
    enc.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

function b64url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes)).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

/** state = base64url(payload).base64url(hmac) so the callback can trust uid. */
export async function signState(uid: string, provider: string): Promise<string> {
  const payload = enc.encode(JSON.stringify({ uid, provider, n: crypto.randomUUID() }));
  const key = await hmacKey();
  const sig = new Uint8Array(await crypto.subtle.sign("HMAC", key, payload));
  return `${b64url(payload)}.${b64url(sig)}`;
}

export async function verifyState(
  state: string,
): Promise<{ uid: string; provider: string } | null> {
  const [p, s] = state.split(".");
  if (!p || !s) return null;
  const payload = Uint8Array.from(
    atob(p.replaceAll("-", "+").replaceAll("_", "/")),
    (c) => c.charCodeAt(0),
  );
  const sig = Uint8Array.from(
    atob(s.replaceAll("-", "+").replaceAll("_", "/")),
    (c) => c.charCodeAt(0),
  );
  const key = await hmacKey();
  const ok = await crypto.subtle.verify("HMAC", key, sig, payload);
  if (!ok) return null;
  try {
    const { uid, provider } = JSON.parse(new TextDecoder().decode(payload));
    return { uid, provider };
  } catch {
    return null;
  }
}
