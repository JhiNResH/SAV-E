import CoreLocation
import Foundation

struct SaveLocationIntentRecommendationService {
    private let parser: SaveSearchIntentParser

    init(parser: SaveSearchIntentParser = SaveSearchIntentParser()) {
        self.parser = parser
    }

    func requiresCurrentLocation(for query: String) -> Bool {
        guard let intent = parser.parse(query) else { return false }
        return intent.mustMatchLocation
    }

    func recommendationResponse(
        for query: String,
        places: [Place],
        currentLocation: CLLocation?
    ) -> SaveAIResponse? {
        guard let intent = parser.parse(query),
              intent.kind == .categoryRecommendation || intent.kind == .craving || intent.mustMatchLocation else {
            return nil
        }

        if let unsupportedCategoryLabel = intent.unsupportedCategoryLabel {
            return messageResponse(
                title: "Unsupported category",
                message: "SAV-E doesn't have a \(unsupportedCategoryLabel) category yet, so I won't map this to food or cafe by accident. You can search saved names/notes, or ask to search public nearby places."
            )
        }

        guard !intent.requiredCategories.isEmpty else { return nil }

        if intent.mustMatchLocation, currentLocation == nil {
            return messageResponse(
                title: "Location needed",
                message: "I need your current location before I can answer nearby requests. Or ask for saved \(categoryLabel(for: intent)) anywhere."
            )
        }

        let categoryMatches = places.filter { place in
            intent.requiredCategories.contains(place.category)
        }
        let rankedCategoryMatches = rank(categoryMatches, for: intent, currentLocation: currentLocation)

        if intent.mustMatchLocation,
           case .currentLocation(let radiusMeters) = intent.locationMode,
           let currentLocation {
            let nearby = rankedCategoryMatches.filter {
                distanceMeters(from: currentLocation, to: $0) <= radiusMeters
            }
            let far = rankedCategoryMatches.filter {
                distanceMeters(from: currentLocation, to: $0) > radiusMeters
            }

            guard !nearby.isEmpty else {
                let farContext = far.isEmpty
                    ? ""
                    : " You do have saved \(categoryLabel(for: intent)) places, but the closest one is outside the nearby radius."
                return messageResponse(
                    title: "No nearby \(categoryLabel(for: intent))",
                    message: "你的 SAV-E 裡附近沒有\(localizedCategoryLabel(for: intent))。I did not recommend other categories because you asked for \(categoryLabel(for: intent)).\(farContext)"
                )
            }

            return placeListResponse(
                title: "Nearby \(categoryLabel(for: intent))",
                places: nearby,
                aiMessage: "Found \(nearby.count) saved nearby \(categoryLabel(for: intent)) place\(nearby.count == 1 ? "" : "s") from your SAV-E."
            )
        }

        guard !rankedCategoryMatches.isEmpty else {
            return messageResponse(
                title: "No saved \(categoryLabel(for: intent))",
                message: "Your SAV-E does not have saved \(categoryLabel(for: intent)) places yet."
            )
        }

        return placeListResponse(
            title: "Saved \(categoryLabel(for: intent))",
            places: rankedCategoryMatches,
            aiMessage: "Showing saved \(categoryLabel(for: intent)) places from your SAV-E."
        )
    }

    private func rank(_ places: [Place], for intent: SaveSearchIntent, currentLocation: CLLocation?) -> [Place] {
        places.sorted { lhs, rhs in
            let lhsNeedleScore = evidenceScore(lhs, needles: intent.categoryNeedles)
            let rhsNeedleScore = evidenceScore(rhs, needles: intent.categoryNeedles)
            if lhsNeedleScore != rhsNeedleScore { return lhsNeedleScore > rhsNeedleScore }

            if let currentLocation {
                return distanceMeters(from: currentLocation, to: lhs) < distanceMeters(from: currentLocation, to: rhs)
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private func evidenceScore(_ place: Place, needles: [String]) -> Int {
        guard !needles.isEmpty else { return 0 }
        let haystack = SaveSearchIntentParser.normalize(
            [
                place.name,
                place.address,
                place.note ?? "",
                place.extractedDishes?.joined(separator: " ") ?? ""
            ].joined(separator: " ")
        )
        return needles.reduce(0) { score, needle in
            haystack.contains(needle) ? score + 1 : score
        }
    }

    private func distanceMeters(from currentLocation: CLLocation, to place: Place) -> CLLocationDistance {
        currentLocation.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
    }

    private func placeListResponse(title: String, places: [Place], aiMessage: String) -> SaveAIResponse {
        let ids = places.map { $0.id.uuidString }
        return SaveAIResponse(
            componentType: .placeList,
            title: title,
            placeIds: ids,
            navigationPlaceId: nil,
            transportMode: .walking,
            itineraryDays: [],
            messageText: nil,
            mapAction: MapActionData(type: .filterPins, placeIds: ids, lat: nil, lng: nil, span: nil),
            aiMessage: aiMessage
        )
    }

    private func messageResponse(title: String, message: String) -> SaveAIResponse {
        SaveAIResponse(
            componentType: .message,
            title: title,
            placeIds: [],
            navigationPlaceId: nil,
            transportMode: .walking,
            itineraryDays: [],
            messageText: message,
            mapAction: nil,
            aiMessage: message
        )
    }

    private func categoryLabel(for intent: SaveSearchIntent) -> String {
        guard let category = intent.requiredCategories.first else { return "places" }
        return category.displayName.lowercased()
    }

    private func localizedCategoryLabel(for intent: SaveSearchIntent) -> String {
        guard let category = intent.requiredCategories.first else { return "地點" }
        switch category {
        case .food: return "餐廳"
        case .cafe: return "咖啡廳"
        case .bar: return "酒吧"
        case .attraction: return "景點"
        case .stay: return "住宿"
        case .shopping: return "購物地點"
        }
    }
}
