import Foundation
import CoreLocation

/// Shared business-details enrichment used by both `PlaceDetailView` and
/// `PlaceBottomSheet` so they stay in sync. Resolves Google Places photo
/// references / rating / price / hours for a place and returns an updated
/// `Place` with the new values merged in (existing values win).
enum PlaceBusinessEnricher {
    struct Update {
        let photoURLs: [URL]
        let rating: Double?
        let priceRange: String?
        let openingHours: String?
    }

    /// Whether the place is still missing details worth fetching. Mirrors the
    /// guard used historically in `PlaceDetailView.enrichBusinessDetails`.
    static func needsEnrichment(_ place: Place) -> Bool {
        place.businessPhotoURLStrings.count < 2 ||
            place.googleRating == nil ||
            place.priceRange == nil ||
            place.openingHours == nil
    }

    /// Returns a place with freshly enriched fields merged in, or `nil` if no
    /// new details were found. Never overwrites values the place already has.
    static func enrich(
        _ place: Place,
        service: GooglePlacesServiceProtocol = GooglePlacesService.shared
    ) async -> Place? {
        guard needsEnrichment(place) else { return nil }
        guard let update = await businessDetails(for: place, service: service) else { return nil }

        var updated = place
        if !update.photoURLs.isEmpty {
            let urls = update.photoURLs.map(\.absoluteString)
            updated.sourceImageUrl = updated.sourceImageUrl ?? urls.first
            updated.businessPhotoUrls = urls
        }
        updated.googleRating = updated.googleRating ?? update.rating
        updated.priceRange = updated.priceRange ?? update.priceRange
        updated.openingHours = updated.openingHours ?? update.openingHours
        return updated
    }

    private static func businessDetails(
        for place: Place,
        service: GooglePlacesServiceProtocol
    ) async -> Update? {
        let details: GooglePlaceDetails?
        let fallbackMatch: GooglePlaceMatch?
        if let googlePlaceId = place.googlePlaceId {
            details = try? await service.getPlaceDetails(placeId: googlePlaceId)
            fallbackMatch = nil
        } else {
            guard let match = await bestGoogleMatch(for: place, service: service) else { return nil }
            details = try? await service.getPlaceDetails(placeId: match.id)
            fallbackMatch = match
        }

        let photoReferences = details?.photoReferences?.isEmpty == false
            ? details?.photoReferences ?? []
            : [fallbackMatch?.photoReference].compactMap { $0 }
        let photoURLs = photoReferences
            .prefix(6)
            .compactMap { service.photoURL(reference: $0, maxWidth: 900) }
        let priceLevel = details?.priceLevel ?? fallbackMatch?.priceLevel
        let hasDetails = !photoURLs.isEmpty ||
            details?.rating != nil ||
            fallbackMatch?.rating != nil ||
            priceLevel != nil ||
            details?.openingHours?.isEmpty == false
        guard hasDetails else { return nil }

        return Update(
            photoURLs: photoURLs,
            rating: details?.rating ?? fallbackMatch?.rating,
            priceRange: priceLevel.map { String(repeating: "$", count: max(1, $0)) },
            openingHours: details?.openingHours?.first
        )
    }

    private static func bestGoogleMatch(
        for place: Place,
        service: GooglePlacesServiceProtocol
    ) async -> GooglePlaceMatch? {
        do {
            let matches = try await service.searchPlace(
                query: "\(place.name) \(place.address)",
                near: place.coordinate
            )
            let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            return matches.first { match in
                let matchLocation = CLLocation(latitude: match.latitude, longitude: match.longitude)
                let sameArea = placeLocation.distance(from: matchLocation) < 250
                let sameName = match.name.localizedCaseInsensitiveContains(place.name) ||
                    place.name.localizedCaseInsensitiveContains(match.name)
                return sameArea || sameName
            }
        } catch {
            return nil
        }
    }
}
