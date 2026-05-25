# SAV-E Agent-First Map, Drawer, Trip Planner, and Guides v0

## Product Call

SAV-E should not become a tab-heavy Google Maps clone. The app can keep the current drawer/bottom-sheet pattern if the drawer is the agent surface: it should expose context-aware actions for the selected place, source, map area, or trip intent.

Core loop:

```text
map/search/social source
→ inspect place in drawer
→ save / recover / plan around / add to trip
→ review after visit
→ optional receipt-backed memory
```

## Roamy-Informed Parity Rules

- Map-visible unsaved places are first-class candidates, not saved memories.
- User can tap an unsaved map place and explicitly save it.
- Each place/candidate should preserve clickable source links when available: Instagram, TikTok, Google Maps, Apple Maps, screenshots, captions/OCR.
- Ratings/review counts can be displayed for external map places, but must not be confused with SAV-E private reviews.
- Nearby should show saved places, unsaved map candidates, and recommended places as separate sections.

## Drawer vs Tabs

Current drawer approach is acceptable and likely better for an agent-native product than adding many tabs.

Recommended navigation principle:

```text
Few persistent surfaces:
- Map/Search
- Saves/Memory
- Trips

Most functionality:
- contextual drawer actions
- agent command bar
- place/trip bottom sheets
```

Avoid adding a tab for every capability. The agent should route intents like:

- “save this place”
- “find exact source”
- “plan around this restaurant”
- “nearby things to do”
- “customize this guide with my saved places”

## Unsaved Map Candidate Model

The map can show places that are not in the user's SAV-E yet. They should render as `Map place / Unsaved` and expose primary action `Save this place`.

Acceptance:

- Unsaved map candidate appears under `New recommendations`, not `From your SAV-E`.
- Unsaved map candidate can carry coordinates, rating, review count, category, map/source URL, and evidence.
- Saving one should create a normal saved place/memory card later; this spec only adds the searchable representation.

## AI Trip Planner: Plan Around My Places

Primary differentiation from fixed itinerary apps:

```text
Use the user's saved food/place graph as anchors, then add nearby activities and route constraints.
```

Inputs:

- anchor saved places
- city/neighborhood/current map region
- duration/date/time window
- transport mode
- pace
- vibe/category goals
- budget constraints
- must-include / avoid list

Output:

- day or half-day itinerary
- stop order
- map route
- saved vs new labels
- why each new stop was added
- alternates / swap suggestions

Ranking priority:

1. User saved places
2. Pending candidates with enough evidence
3. Places from saved/copied guides
4. Unsaved map candidates near anchors
5. New web/map recommendations

## Guides

Guides should start as copyable itinerary templates, not a full social feed.

MVP actions:

- view public/shared guide
- save guide
- copy to my trips
- add all guide stops to SAV-E
- customize guide with my saved places

AI customization:

```text
creator guide + my saved places + constraints
→ keep relevant stops
→ swap in my saved places nearby
→ add missing activities/cafes/views
→ optimize route
```

## Out of Scope for This Cut

- Full map provider search integration
- Persisting unsaved map candidates to backend
- Actual save action wiring from search result cards
- Full AI route generation
- Public guide feed / following / comments
- Payment, wallet, chain, or merchant integrations

## Implementation Slice in This PR

- Add `SaveMapCandidate` as a searchable unsaved map-place representation.
- Add `mapVisibleUnsavedPlace` result type.
- Add rating/review-count/action metadata to search results.
- Keep map candidates separate in `New recommendations` until the user explicitly saves them.
- Document the agent-first drawer strategy and AI trip/guides direction.
