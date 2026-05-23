# Source-Only Search Recovery Plan

## Summary
When SAV-E receives an Instagram/social URL but cannot extract a reliable place candidate, keep it source-only and attach a concrete public-search recovery plan.

## Problem
URL-only Reels often do not expose enough public metadata to identify a place. The app should not fake a place, but the user also needs to see what the agent would try next.

## Scope
- Add suggested public search queries to `SocialPlaceEvidenceDiagnostic`.
- Preserve backward compatibility for existing local vault records that do not include search queries.
- Populate search queries for source-only main app imports, local vault saves, and Share Extension fallbacks.
- Show the queries in evidence/debug surfaces.

## Non-goals
- No logged-in Instagram scraping.
- No external search API integration.
- No automatic video download, frame extraction, or OCR expansion.
- No direct save from source-only evidence.

## Acceptance Criteria
- URL-only Instagram Reels remain source-only candidates.
- Source-only diagnostics include suggested public search queries such as `instagram reel <id> place`.
- Tracking query strings are removed from canonical URL search queries.
- Existing saved diagnostics without search queries still decode.
- Build and social pipeline tests pass.
