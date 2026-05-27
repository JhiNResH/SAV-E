# Friend and Trending Map Signals v0

## Problem

SAV-E can save personal places and shared lists, but the map still lacks memory-first social discovery: friends' places, trending category signals, referral entry, and a clear "Save to my SAV-E" action.

## Goal

Add a v0 social signal layer that makes friend and trending places visible without turning SAV-E into a generic public feed.

## Scope

- Data model contract for `follows`, `place_social_signals`, and `place_visibility`.
- Drawer surface with `For You`, `Friends`, and `Trending` lenses.
- Place cards show friend or trending signal context.
- Map pins show friend/trending source state.
- Social candidate action: `Save to my SAV-E`.
- Referral profile links:
  - `https://sav-e.app/r/<code>`
  - `https://sav-e.app/u/<handle>?ref=<code>`
- App Clip referral preview for profile + featured places + follow CTA.
- Full app referral handoff stores referrer + intended follow lens for completion after install/open.

## Acceptance Criteria

1. Drawer idle state includes a segmented social lens control for `For You`, `Friends`, and `Trending`.
2. Each social candidate shows source context such as friend saves, trending rank, or referral guide.
3. Social candidates can be saved into the user's own SAV-E without being treated as already-owned memories.
4. Map annotations visually distinguish friend/trending/referral places from private Map Stamps.
5. Saved place cards can display a friend/trending signal when available.
6. Backend schema contains follow graph, place visibility, and place social signal tables.
7. App and App Clip parse referral URLs and route to referral preview/handoff.
8. No real reward-credit accounting, public social feed, comments, or backend ranking algorithm is shipped in this PR.

## Verification

- iOS simulator build for `Wanderly`.
- iOS simulator build for `WanderlyClip`.
- Backend TypeScript build.
- `git diff --check`.

## Follow-Up

- Backend endpoints for `GET /social/signals`, `POST /follows`, and referral reward receipts.
- Production `sav-e.app` AASA/App Clip domain setup.
- Real profile/featured-place fetch for referral previews.
