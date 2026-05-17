# No Fake Coordinates and Review Candidate UI

> Last updated: 2026-05-16

## Problem

SAV-E can receive links from social posts, event pages, generic articles, and map URLs. If a link does not carry reliable coordinates, the product must not create a fake saved place or pin. Earlier RN link parsing still used San Francisco fallback coordinates for event and generic links, which can make unrelated places appear in the wrong city and makes later itinerary planning unreliable.

## Goal

Unresolved imports should become review candidates. Confirmed saved places should only be created when coordinates come from a reliable source: explicit map coordinates, Google Places refinement, or a map/place link supplied by the user.

## Acceptance Criteria

- RN event and generic link parsing returns unresolved draft coordinates `0,0`, never San Francisco fallback coordinates.
- Google Maps / Apple Maps links without explicit coordinates become draft imports, not direct saved places.
- Native iOS shows a real Review candidates list loaded from `GET /memory/candidates`.
- Candidate cards support confirm, reject, and save as place.
- Save as place refines missing coordinates through Google Places when possible.
- Save as place is blocked when there is no reliable coordinate after refinement; the UI must ask for Google Places configuration or a map link instead of creating a fake pin.
- Link parser fixtures cover Instagram, Google Maps, Luma, and generic article examples.

## Out of Scope

- Automatic platform video downloading.
- Full Instagram/TikTok/XHS authenticated extraction.
- Backend candidate schema changes.
- Auto-saving review candidates without user action.
- TestFlight upload, deployment, or PR merge.

## Verification

- RN TypeScript check.
- RN link parser fixture check.
- Backend build.
- iOS build with code signing disabled.
- `git diff --check`.
