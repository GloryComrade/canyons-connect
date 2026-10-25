// OAuth provider config + signed-state helpers (Node crypto).
import * as crypto from "crypto";

export interface OAuthProviderConfig {
  authorizeUrl: string;
  tokenUrl: string;
  clientId: string;
  clientSecret: string;
  scopes: string;
}

export function oauthConfig(provider: string): OAuthProviderConfig | null {
  switch (provider) {
    case "canvas": {
      const base = process.env.CANVAS_BASE_URL ?? "";
      return {
        authorizeUrl: `${base}/login/oauth2/auth`,
        tokenUrl: `${base}/login/oauth2/token`,
        clientId: process.env.CANVAS_CLIENT_ID ?? "",
        clientSecret: process.env.CANVAS_CLIENT_SECRET ?? "",
        // Read-only: courses, assignments (with nested submission), submissions.
        // Keep write/submit scopes OUT — students complete work in Canvas itself.
        scopes:
          "url:GET|/api/v1/courses " +
          "url:GET|/api/v1/courses/:course_id/assignments " +
          "url:GET|/api/v1/courses/:course_id/assignments/:id " +
          "url:GET|/api/v1/courses/:course_id/assignments/:id/submissions " +
          "url:GET|/api/v1/courses/:course_id/assignments/:id/submissions/:id " +
          "url:GET|/api/v1/courses/:course_id/students/submissions " +
          "url:GET|/api/v1/announcements " +
          "url:GET|/api/v1/users/self/assignments " +
          "url:GET|/api/v1/calendar_events",
      };
    }
    case "groupme":
      return {
        authorizeUrl: "https://oauth.groupme.com/oauth/authorize",
        tokenUrl: "",
        clientId: process.env.GROUPME_CLIENT_ID ?? "",
        clientSecret: process.env.GROUPME_CLIENT_SECRET ?? "",
        scopes: "",
      };
    default:
      return null;
  }
}

function hmac(payload: string): string {
  return crypto
    .createHmac("sha256", process.env.STATE_SIGNING_SECRET ?? "")
    .update(payload)
    .digest("base64url");
}

export function signState(uid: string, provider: string): string {
  const payload = Buffer.from(
    JSON.stringify({ uid, provider, n: crypto.randomUUID() })
  ).toString("base64url");
  return `${payload}.${hmac(payload)}`;
}

export function verifyState(
  state: string
): { uid: string; provider: string } | null {
  const [payload, sig] = state.split(".");
  if (!payload || !sig) return null;
  if (hmac(payload) !== sig) return null;
  try {
    const { uid, provider } = JSON.parse(
      Buffer.from(payload, "base64url").toString("utf8")
    );
    return { uid, provider };
  } catch {
    return null;
  }
}
