# SAV-E Memory-First Command Drawer

> Last updated: 2026-05-26
> Status: implementation spec

## Product Call

Google Maps can use Gemini to recommend nearby public places. SAV-E should win on
private memory: recommending and planning from the user's saved Map Stamps, Review
Candidates, source clues, and imported lists.

## Goal

Make the map feel as clean as Apple Maps while moving SAV-E-specific controls into
the bottom drawer.

Core loop:

```text
clean map
-> command drawer text or mic
-> SAV-E saved memory results first
-> explicit nearby unsaved candidate search only when requested
```

## In Scope

- Remove the persistent top category rail from the map.
- Keep compact SAV-E/Memo identity, Passport, and current-location controls.
- Move category filters into the drawer.
- Add a mic button that dictates into the same command text field.
- Keep search/recommendation saved-memory-first.
- Show "Search nearby unsaved candidates" only as an explicit action.
- Stop eager nearby candidate refresh on map load, pan, and current-location focus.

## Out of Scope

- New tabs.
- New backend schema.
- Full voice-agent conversation mode.
- Google Directions / route optimization.
- TestFlight build-number changes.
- Merge or deploy.

## Acceptance Criteria

- First map view has minimal top chrome.
- Category filters are reachable from the drawer.
- Drawer collapsed state supports text command, mic, clear, and submit.
- Mic states cover idle, permission request, listening, unavailable, denied, and failed.
- Query submission still reuses the existing saved-memory search path.
- Nearby unsaved candidates appear only after an explicit drawer action.
- iOS build passes.
