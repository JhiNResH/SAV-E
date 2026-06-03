# Verified Place Claims API Phase 1.5

> Last updated: 2026-06-03
> Source: `/Users/jhinresh/brain/wiki/projects/wanderly/save-verified-place-claims-api.md`

## Goal

Add an owner-scoped API layer that makes SAV-E place memory agent-callable as
structured claims instead of vague reviews.

```text
confirmed/sourced place memory
-> verified place claim
-> proof level + evidence summary + visibility
-> trust summary / recommendation by claims
```

## First Slice

- Add `place_claims`.
- Add private authenticated routes:
  - `GET /v0/places/:placeId/verified-claims`
  - `POST /v0/places/:placeId/verified-claims`
  - `GET /v0/places/:placeId/trust-summary`
  - `POST /v0/places/recommend-by-claims`
- Add public projection / receipt routes:
  - `GET /public/v0/cards/:cardId`
  - `POST /public/v0/claim-usage-receipts`
  - `POST /v0/claims/usage-receipts`
- Keep all claim queries owner-scoped.
- Return evidence summaries by default; raw `evidence_refs` only when explicitly
  requested by the owner.
- Return retrieval receipt for claim-based recommendation.
- Use usage receipt aggregate as a small ranking boost after proof level and
  confidence.

## Out Of Scope

- Public collections.
- OpenAPI / `llms.txt` / agent manifest.
- Paid/API-key-gated claim access.
- Booking, ordering, payments, external messages, or phone automation.
- Publishing raw private sources.

## Acceptance

- Claims attach to a user-owned place with proof level, confidence, visibility,
  evidence refs, context, ratings, and agent-usable summary.
- Trust summary reports proof-level-weighted counts, strongest proof, confidence,
  warnings, reputation aggregate, and recommended use.
- Recommendation by claims ranks owner-scoped places only and reports used/skipped
  claims with `public_web_used=false`.
- Public cards expose only public/link-shared claims and never raw evidence refs.
- Usage receipts can be created for public claims or owner-authenticated claims.
- Backend TypeScript tests pass.
