// AES-GCM encryption for login credentials stored in integration_secrets.
// The key is a base64-encoded 32-byte value in the CREDENTIALS_ENC_KEY secret.
// (For production you may prefer Supabase Vault / pgsodium; this keeps the
// ciphertext self-contained and portable.)

function keyBytes(): Uint8Array {
  const b64 = Deno.env.get("CREDENTIALS_ENC_KEY");
  if (!b64) throw new Error("CREDENTIALS_ENC_KEY is not set");
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

async function importKey(): Promise<CryptoKey> {
  return await crypto.subtle.importKey(
    "raw",
    keyBytes(),
    { name: "AES-GCM" },
    false,
    ["encrypt", "decrypt"],
  );
}

export async function encryptJson(value: unknown): Promise<string> {
  const key = await importKey();
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const data = new TextEncoder().encode(JSON.stringify(value));
  const cipher = new Uint8Array(
    await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, data),
  );
  const out = new Uint8Array(iv.length + cipher.length);
  out.set(iv, 0);
  out.set(cipher, iv.length);
  return btoa(String.fromCharCode(...out));
}

export async function decryptJson<T = unknown>(payload: string): Promise<T> {
  const key = await importKey();
  const bytes = Uint8Array.from(atob(payload), (c) => c.charCodeAt(0));
  const iv = bytes.slice(0, 12);
  const cipher = bytes.slice(12);
  const plain = await crypto.subtle.decrypt({ name: "AES-GCM", iv }, key, cipher);
  return JSON.parse(new TextDecoder().decode(plain)) as T;
}
