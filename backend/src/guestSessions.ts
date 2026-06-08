import { createHmac, randomUUID, timingSafeEqual } from "node:crypto";

export type GuestSession = {
  guest_id: string;
  guest_token: string;
  expires_at: string;
};

type GuestSessionPayload = {
  v: 1;
  sub: string;
  iat: number;
  exp: number;
};

const tokenPrefix = "save_guest_v1";
const guestIdPattern = /^guest_[0-9a-fA-F-]{36}$/;
const defaultGuestSessionTtlSeconds = 60 * 60 * 24 * 180;

export function createGuestSession(
  secret: string,
  now = new Date(),
  ttlSeconds = defaultGuestSessionTtlSeconds,
): GuestSession {
  const issuedAt = Math.floor(now.getTime() / 1000);
  const expiresAt = issuedAt + ttlSeconds;
  const guestId = `guest_${randomUUID()}`;
  const payload: GuestSessionPayload = {
    v: 1,
    sub: guestId,
    iat: issuedAt,
    exp: expiresAt,
  };

  return {
    guest_id: guestId,
    guest_token: signGuestSessionPayload(secret, payload),
    expires_at: new Date(expiresAt * 1000).toISOString(),
  };
}

export function userIdFromGuestSessionToken(token: string, secret: string, now = new Date()): string | undefined {
  const parts = token.split(".");
  if (parts.length !== 3 || parts[0] !== tokenPrefix) return undefined;

  const [, encodedPayload, signature] = parts;
  const expectedSignature = hmac(secret, encodedPayload);
  if (!constantTimeEqual(signature, expectedSignature)) return undefined;

  const payload = decodePayload(encodedPayload);
  if (!payload) return undefined;
  if (payload.v !== 1 || !guestIdPattern.test(payload.sub)) return undefined;
  if (payload.exp <= Math.floor(now.getTime() / 1000)) return undefined;
  return payload.sub;
}

function signGuestSessionPayload(secret: string, payload: GuestSessionPayload): string {
  const encodedPayload = base64url(JSON.stringify(payload));
  return `${tokenPrefix}.${encodedPayload}.${hmac(secret, encodedPayload)}`;
}

function decodePayload(encodedPayload: string): GuestSessionPayload | undefined {
  try {
    const payload = JSON.parse(Buffer.from(encodedPayload, "base64url").toString("utf8")) as Partial<GuestSessionPayload>;
    if (payload.v !== 1 || typeof payload.sub !== "string" || typeof payload.iat !== "number" || typeof payload.exp !== "number") {
      return undefined;
    }
    return payload as GuestSessionPayload;
  } catch {
    return undefined;
  }
}

function hmac(secret: string, value: string): string {
  return createHmac("sha256", secret).update(value).digest("base64url");
}

function base64url(value: string): string {
  return Buffer.from(value, "utf8").toString("base64url");
}

function constantTimeEqual(left: string, right: string): boolean {
  const leftBuffer = Buffer.from(left);
  const rightBuffer = Buffer.from(right);
  return leftBuffer.length === rightBuffer.length && timingSafeEqual(leftBuffer, rightBuffer);
}
