import assert from "node:assert/strict";
import test from "node:test";
import {
  normalizeFollowRequest,
  normalizeVisibilityRequest,
  parseLens,
  socialSignalKindForLens,
} from "./socialContracts.js";

test("normalizeFollowRequest resolves referral defaults without trusting invalid lens", () => {
  const request = normalizeFollowRequest({
    handle: "@MemoGuide",
    referral_code: "SAVE-123",
    lens: "anything",
  });

  assert.deepEqual(request, {
    followingId: undefined,
    handle: "memoguide",
    referralCode: "SAVE-123",
    lens: "friends",
    source: "referral",
  });
});

test("normalizeVisibilityRequest never allows private places to emit social signals", () => {
  assert.deepEqual(
    normalizeVisibilityRequest({
      visibility: "private",
      allow_friend_signal: true,
      allow_trending_signal: true,
    }),
    {
      visibility: "private",
      allowFriendSignal: false,
      allowTrendingSignal: false,
    },
  );
});

test("normalizeVisibilityRequest preserves explicit opt-in for public guide places", () => {
  assert.deepEqual(
    normalizeVisibilityRequest({
      visibility: "public_guide",
      allow_friend_signal: true,
      allow_trending_signal: true,
    }),
    {
      visibility: "public_guide",
      allowFriendSignal: true,
      allowTrendingSignal: true,
    },
  );
});

test("social lens parsing keeps invalid values bounded", () => {
  assert.equal(parseLens("trending"), "trending");
  assert.equal(parseLens("forYou"), "forYou");
  assert.equal(parseLens("public"), "friends");
  assert.equal(socialSignalKindForLens("trending"), "trending");
  assert.equal(socialSignalKindForLens("friends"), "friend_saved");
});
