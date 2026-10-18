// AES-256-GCM encryption for login credentials stored in integration_secrets.
// Key is base64 (32 bytes) in CREDENTIALS_ENC_KEY.
import * as crypto from "crypto";

function key(): Buffer {
  const b64 = process.env.CREDENTIALS_ENC_KEY;
  if (!b64) throw new Error("CREDENTIALS_ENC_KEY not set");
  return Buffer.from(b64, "base64");
}

export function encryptJson(value: unknown): string {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv("aes-256-gcm", key(), iv);
  const data = Buffer.concat([
    cipher.update(JSON.stringify(value), "utf8"),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, data]).toString("base64");
}

export function decryptJson<T = unknown>(payload: string): T {
  const b = Buffer.from(payload, "base64");
  const iv = b.subarray(0, 12);
  const tag = b.subarray(12, 28);
  const data = b.subarray(28);
  const decipher = crypto.createDecipheriv("aes-256-gcm", key(), iv);
  decipher.setAuthTag(tag);
  const plain = Buffer.concat([decipher.update(data), decipher.final()]);
  return JSON.parse(plain.toString("utf8")) as T;
}
