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
- Keep all claim queries owner-scoped.
- Return evidence summaries by default; raw `evidence_refs` only when explicitly
  requested by the owner.
- Return retrieval receipt for claim-based recommendation.

## Public Projection / Usage Slice

- Add public projection route:
  - `GET /public/v0/cards/:placeId`
- Add bounded usage receipt routes:
  - `POST /public/v0/claim-usage-receipts`
  - `POST /v0/claims/usage-receipts`
- Public cards expose only public-link/public-guide places and public/link-shared
  claims.
- Public cards include proof labels, evidence summaries, trust summary, and
  agent actions, but never raw private `evidence_refs`.
- Usage receipts aggregate into claim reputation fields:
  - `usage_count`
  - `accepted_count`
  - `score`
- Claim recommendation may use reputation as a small ranking boost, while still
  requiring proof-level and owner-scope gates.

## Out Of Scope

- Public collections.
- OpenAPI / `llms.txt` / agent manifest.
- Paid/API-key-gated claim access or broad reputation graph exports.
- Booking, ordering, payments, external messages, or phone automation.
- Publishing raw private sources.

## Acceptance

- Claims attach to a user-owned place with proof level, confidence, visibility,
  evidence refs, context, ratings, and agent-usable summary.
- Trust summary reports proof-level-weighted counts, strongest proof, confidence,
  warnings, reputation, and recommended use.
- Recommendation by claims ranks owner-scoped places only and reports used/skipped
  claims with `public_web_used=false`.
- Public place cards expose public claims only and omit raw private evidence.
- Usage receipt creation validates action/outcome and updates reputation inputs.
- Backend TypeScript tests pass.
