# SAV-E Public Test Readiness

Generated: 2026-06-23

This checklist tracks the seven readiness gaps that must stay separate from
"the app builds locally." Local code can prove client behavior; Apple,
production secrets, and device install state require live credentials/device
proof.

## 1. TestFlight and device smoke proof

Current local proof:

- Archive exists at `build/SAV-E-1.0.0-78.xcarchive`.
- Archive metadata shows bundle `com.wanderly.app`, version `1.0.0`, build `78`,
  team `JC6858UYM9`, App Store id `6769216556`.
- Export log `build/logs/export-1.0.0-78-api-4VLSK3YL3V.log` contains
  `Upload succeeded` and `** EXPORT SUCCEEDED **`.
- `Tests/SAVEUITests/SAVEUISmokeHarnessTests.swift` covers the five required
  smoke paths: auth, location, nearby restaurants/cafes, share IG/Maps link,
  review candidate confirm/save.

Still required before public TestFlight:

- Confirm build 78 is visible and processed in App Store Connect.
- Run the five-path smoke harness on a real iPhone with the TestFlight build,
  not only simulator/local debug.
- Save a screenshot or text receipt with device, build number, and pass/fail.

Blocked locally when these are missing:

- `APP_STORE_CONNECT_API_KEY_PATH`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`

## 2. App Clip and shared links

Required proof:

- `https://sav-e-app.vercel.app/.well-known/apple-app-site-association` serves
  `applinks` and `appclips`.
- `/p/*` pages keep web preview behavior.
- `/p/*` HTML includes an Apple Smart App Banner with the configured App Clip
  bundle id.
- App Store Connect has an App Clip Experience for
  `https://sav-e-app.vercel.app/p/*`.
- iPhone checks:
  - app installed: link opens full SAV-E app.
  - app not installed: link surfaces App Clip or install CTA.

Do not touch Privy auth/session config for this checklist.

## 3. Social link recovery long tail

Current high-risk cases:

- Instagram captions where the venue appears only as a handle inside a quoted
  creator title.
- Instagram posts with multiple venues in one caption.
- URL-only or preview-only iMessage links.
- China/Taiwan food links where OCR contains the address but provider matching
  is missing coordinates.

Required regression behavior:

- Keep creator/source handles separate from venue handles.
- Bind venue handles to the nearest address or pin evidence.
- Return multiple candidates when a post clearly names multiple venues.
- Preserve source-only clues when coordinates are not proven.

## 4. Runtime config risk

Production checks:

- `GEMINI_API_KEY` exists where backend AI analysis runs.
- Google Places key exists where place details are fetched.
- Public web enrichment flag is intentionally enabled or intentionally disabled.
- Privy configuration works for full app and iMessage-created identities.
- Failed AI/place details requests expose a specific status, not only generic
  "AI request failed."

## 5. Nearby/list sorting

Client behavior:

- Saved/review candidates must not outrank truly nearby options just because
  they were saved in another country.
- "Nearest" sort must use current device location when available.
- Without location permission, the app may keep the existing stable order, but
  it must not claim distance-based ranking.

In-repo coverage:

- `testPlaceListNearestSortUsesCurrentLocation`

## 6. Trip and itinerary planning

Current split:

- `DeterministicTripPlanner` handles coordinate-aware itinerary planning from
  saved Map Stamps.
- `TripViewModel` legacy route action only owns stored trip timelines, whose
  `TripStop` records do not contain coordinates.

Client behavior:

- Do not fake Google Directions/Gemini optimization from `TripViewModel`.
- Normalize stored timelines deterministically.
- Use the drawer/detail itinerary planner for coordinate-aware route drafts and
  LLM polish.

In-repo coverage:

- `testTripRouteOptimizationNormalizesTimelineWithoutFakeDelay`

## 7. Backlog and QA ownership

Track as a single public-test gate until all boxes are green:

- Device smoke proof for build 78.
- App Clip/shared-link iPhone proof.
- Production Gemini/Google Places/Privy config proof.
- Social parser golden fixtures for multi-place and handle-only venues.
- Nearby recommendation/list sort regression.
- Itinerary polish path proof from detail page to LLM-polished route.
- Backend deploy receipt after any backend config/code changes.
