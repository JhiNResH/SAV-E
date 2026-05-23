# SAV-E Reel Source Understanding

Status: implemented v1
Date: 2026-05-23

## Goal

SAV-E should treat a shared Reel as a source artifact before treating strings as places.

For multi-place list captions, SAV-E must identify the source type, topic, creator provenance, list groups, and weak venue-handle clues. Group labels and generic caption fragments must not become place candidates.

## V1 Scope

- Add a shared source-level analysis contract in `SocialPlaceParser`.
- Detect multi-place list captions with repeated venue-handle lines and nearby category labels.
- Preserve category labels as source groups, not candidates.
- Preserve creator/source handles as provenance.
- Keep handle-only venues as review-only candidates with no coordinates.
- Add regression coverage for the LA coffee shop Reel list.

## Non-Goals

- No logged-in Instagram scraping.
- No video frame OCR/download.
- No automatic Google Places confirmation.
- No direct save from handle-only evidence.

## Acceptance

- Source type is `multiPlaceList` for the LA coffee list Reel.
- Topic is `coffee shops in Los Angeles County`.
- Groups are preserved:
  - `best for coffee quality`
  - `unique coffee experiences`
  - `atmosphere & aesthetic`
  - `desserts worth it`
- Eight venue handles become weak review candidates.
- `unique coffee experiences`, `MY FAVORITE`, and creator names are never place candidates.
- All candidates remain without coordinates until enrichment/confirmation.
