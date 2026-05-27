# SAV-E Share Routes v0

## Product Rule

Share = SAV-E link.
Maps = Apple Maps link.

Sharing a place or trip must never silently fall back to an Apple Maps URL. Apple Maps remains an explicit Maps action.

## Routes

- `/p/:id` — single place preview.
- `/trip/:id` — trip or itinerary preview.

For v0, `:id` is a URL-safe encoded payload token so the App Clip can preview without a public backend fetch. A backend short ID can replace the token later without changing the route shape.

## App Clip

`/p/:id` shows:
- business photo;
- rating;
- hours;
- address;
- source;
- save/open app action.

`/trip/:id` shows:
- stops;
- route summary;
- copy summary;
- import/open app action.

## Acceptance Criteria

1. `Place.saveShareURL` creates `/p/:id`, not Apple Maps and not `/trip?d=...`.
2. map candidates, search results, and review candidates with coordinates use `/p/:id`.
3. itinerary share uses `/trip/:id`.
4. full app parses both `https://sav-e.app/p/:id` and `wanderly://p/:id`.
5. App Clip parses both `/p/:id` and `/trip/:id`, while keeping legacy `/trip?d=` readable.
6. visible Share buttons use SAV-E links only; visible Maps buttons continue opening Apple Maps.
7. README and secrets template document the route split.

## Out of Scope

- public web renderer;
- backend short-link service;
- authenticated cloud save from App Clip;
- changing list links.
