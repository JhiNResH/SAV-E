import Foundation
import CoreLocation

// MARK: - Protocol

protocol GooglePlacesServiceProtocol {
    func searchPlace(query: String, near: CLLocationCoordinate2D?) async throws -> [GooglePlaceMatch]
    func getPlaceDetails(placeId: String) async throws -> GooglePlaceDetails
}

// MARK: - Models

struct GooglePlaceMatch: Identifiable, Codable {
    let id: String // placeId
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var rating: Double?
    var priceLevel: Int?
}

struct GooglePlaceDetails: Codable {
    var placeId: String
    var name: String
    var formattedAddress: String
    var latitude: Double
    var longitude: Double
    var rating: Double?
    var priceLevel: Int?
    var openingHours: [String]?
    var phoneNumber: String?
    var websiteUrl: String?
    var photoReferences: [String]?
}

// MARK: - Errors

enum GooglePlacesError: LocalizedError {
    case apiKeyMissing
    case noResults
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing: return "Google Places API key not configured"
        case .noResults: return "No matching places found"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Stub Implementation

final class GooglePlacesService: GooglePlacesServiceProtocol {
    static let shared = GooglePlacesService()

    private let apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"]
    }

    func searchPlace(query: String, near: CLLocationCoordinate2D?) async throws -> [GooglePlaceMatch] {
        // TODO: Implement Google Places Text Search
        // GET https://maps.googleapis.com/maps/api/place/textsearch/json
        return [
            GooglePlaceMatch(
                id: "ChIJAQAAMal-j4ARm6sMODkLP28",
                name: query,
                address: "123 Example St",
                latitude: near?.latitude ?? 37.7749,
                longitude: near?.longitude ?? -122.4194,
                rating: 4.5,
                priceLevel: 2
            )
        ]
    }

    func getPlaceDetails(placeId: String) async throws -> GooglePlaceDetails {
        // TODO: Implement Google Places Details
        // GET https://maps.googleapis.com/maps/api/place/details/json
        return GooglePlaceDetails(
            placeId: placeId,
            name: "Example Place",
            formattedAddress: "123 Example St, San Francisco, CA",
            latitude: 37.7749,
            longitude: -122.4194,
            rating: 4.5,
            priceLevel: 2,
            openingHours: ["Mon-Fri: 9:00 AM - 10:00 PM", "Sat-Sun: 10:00 AM - 11:00 PM"],
            phoneNumber: "+1-555-0123",
            websiteUrl: "https://example.com",
            photoReferences: []
        )
    }
}
