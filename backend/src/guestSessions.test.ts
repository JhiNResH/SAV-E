import assert from "node:assert/strict";
import test from "node:test";
import { createGuestSession, userIdFromGuestSessionToken } from "./guestSessions.js";

test("guest sessions verify server-issued guest identity", () => {
  const session = createGuestSession("test-secret", new Date("2026-06-08T00:00:00Z"));

  assert.match(session.guest_id, /^guest_[0-9a-f-]{36}$/);
  assert.equal(
    userIdFromGuestSessionToken(session.guest_token, "test-secret", new Date("2026-06-08T00:01:00Z")),
    session.guest_id,
  );
});

test("guest sessions reject tampered tokens", () => {
  const session = createGuestSession("test-secret", new Date("2026-06-08T00:00:00Z"));
  const parts = session.guest_token.split(".");
  const tamperedPayload = Buffer.from(JSON.stringify({
    v: 1,
    sub: "guest_00000000-0000-4000-8000-000000000000",
    iat: 1_780_358_400,
    exp: 1_795_910_400,
  }), "utf8").toString("base64url");
  const tampered = [parts[0], tamperedPayload, parts[2]].join(".");

  assert.equal(userIdFromGuestSessionToken(tampered, "test-secret", new Date("2026-06-08T00:01:00Z")), undefined);
});

test("guest sessions reject expired tokens", () => {
  const session = createGuestSession("test-secret", new Date("2026-06-08T00:00:00Z"), 60);

  assert.equal(userIdFromGuestSessionToken(session.guest_token, "test-secret", new Date("2026-06-08T00:02:00Z")), undefined);
});
