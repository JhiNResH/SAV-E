# SAV-E Memory Layer

> Last updated: 2026-05-14

## Goal

Add the backend foundation for SAV-E's brain-like product memory:

```text
raw capture
-> place candidate review
-> user decision
-> confirmed saved place / trip action later
```

This gives SAV-E a durable memory trail for links, screenshots, notes, media evidence, and agent investigations without polluting Saved Places before a user confirms.

## Product Contract

SAV-E should store three distinct layers:

- `captures`: raw user inputs such as URLs, notes, screenshots, or video references.
- `place_candidates`: agent-investigated possible places with evidence, confidence, and missing info.
- `agent_decisions`: user or agent decisions such as confirmed, rejected, saved, or added to trip.

Saved Places remain the durable confirmed destination list. Memory candidates do not become Saved Places automatically.

## API Contract

- `GET /memory/captures`
- `POST /memory/captures`
- `GET /memory/captures/:id`
- `PATCH /memory/captures/:id`
- `GET /memory/candidates`
- `POST /memory/candidates`
- `PATCH /memory/candidates/:id`
- `GET /memory/decisions`
- `POST /memory/decisions`

All routes are user-scoped through the same Privy/guest auth path as the rest of the Railway backend.

## Out of Scope

- No iOS UI in this patch.
- No booking, reservation, payment, or SLL-R execution in this patch.
- No automatic platform video downloading.
- No writes to the founder's private `~/brain`.
- No automatic conversion from candidate to Saved Place.

## Acceptance Criteria

- Database schema includes captures, place candidates, and agent decisions.
- Backend exposes user-scoped memory routes.
- Candidates can reference captures and confirmed saved places.
- Decisions can reference candidates.
- TypeScript backend build passes.
- Existing native iOS build still passes.
