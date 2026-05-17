# Social Handle Review Candidates

> Last updated: 2026-05-16

## Goal

Handle Instagram/Reel cases where public metadata exposes a venue handle such as `@ulamanbali`, but does not expose structured location metadata, address, or coordinates.

SAV-E should turn this into a review candidate, not a Saved Place.

## Product Contract

```text
social URL + public caption metadata
-> extract candidate handle / title evidence
-> store pending review candidate
-> main app writes capture + place_candidate to Railway memory API
-> user reviews before saving
```

The app must not create fake coordinates or default uncertain social imports to San Francisco.

## Acceptance Criteria

- Native share extension extracts usable social handles from public metadata evidence.
- Handle-only social imports go to review candidate storage, not `pendingPlaces`.
- Main app consumes pending review candidates and writes `captures` + `place_candidates`.
- Candidate evidence includes the handle, source URL, and metadata text.
- Candidate confidence stays below direct-save confidence and status remains `review`.
- RN web social draft imports use neutral `0,0` draft coordinates, not San Francisco.
- RN web blocks saving draft imports with unresolved `0,0` coordinates.
- TypeScript and native iOS builds pass.

## Out of Scope

- No automatic platform video download.
- No real Google Places / official-site corroboration in this patch.
- No automatic save to Saved Places.
- No new candidate review UI in this patch.
