# Source Search Worker

## Summary
Execute source-only search recovery queries on the backend and write search-derived candidates back into Review.

## Problem
SAV-E can now produce search queries for URL-only social links, but those queries are inert unless a trusted backend worker executes them and records the results.

## Scope
- Add a backend public-search worker for source-only captures.
- Add `POST /memory/captures/:id/search-recovery`.
- Parse public search result titles/snippets into review-only place candidates.
- Keep created candidates without coordinates and with verification missing info.
- Trigger recovery from native iOS when a source-only candidate is persisted.

## Non-goals
- No logged-in Instagram scraping.
- No paid search API or credential changes.
- No direct save to places.
- No automatic video download or frame OCR.

## Acceptance Criteria
- Source-only URL imports can trigger backend search recovery.
- Search-derived results are inserted as `place_candidates` with `status = review`.
- Candidates include evidence pointing to query/result title/snippet/source URL.
- Existing candidate duplicates for the same capture are not reinserted.
- Backend tests, TypeScript build, iOS tests, and iOS generic build pass.
