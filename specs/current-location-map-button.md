# Current Location Map Button

## Summary
Add an obvious native iOS map control that returns the camera to the user's current location.

## Problem
`MapView` already requests user location on launch and includes Apple's default `MapUserLocationButton`, but the control is not visually obvious in SAV-E's current layout and can be easy to miss around the category bar and drawer.

## Scope
- Add a floating SAV-E-styled button on the map surface.
- Reuse `MapViewModel.focusOnUserLocation()`.
- Show a loading state while location is resolving.
- Keep the button above the collapsed drawer area.

## Non-goals
- No TestFlight build bump.
- No changes to authorization strings or location persistence.
- No backend changes.

## Acceptance Criteria
- Tapping the button asks for location if needed and recenters the map when a location is available.
- The button is reachable with VoiceOver.
- Existing category/profile bar remains unchanged.
