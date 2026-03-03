import Foundation

// MARK: - Protocol

protocol AIParsingServiceProtocol {
    func parseURL(_ url: URL) async throws -> ParsedPlaceResult
    func parseImage(_ imageData: Data) async throws -> ParsedPlaceResult
}

// MARK: - Parsed Result

struct ParsedPlaceResult: Codable {
    var placeName: String?
    var address: String?
    var category: PlaceCategory?
    var dishes: [String]?
    var priceRange: String?
    var recommender: String?
    var confidence: Double
}

// MARK: - Errors

enum AIParsingError: LocalizedError {
    case invalidResponse
    case apiKeyMissing
    case networkError(Error)
    case parsingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from AI service"
        case .apiKeyMissing: return "Claude API key not configured"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .parsingFailed(let reason): return "Parsing failed: \(reason)"
        }
    }
}

// MARK: - Stub Implementation

final class AIParsingService: AIParsingServiceProtocol {
    static let shared = AIParsingService()

    private let apiKey: String?

    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
    }

    func parseURL(_ url: URL) async throws -> ParsedPlaceResult {
        // TODO: Implement Claude Vision API call
        // POST to https://api.anthropic.com/v1/messages
        // with image/url content for place extraction
        return ParsedPlaceResult(
            placeName: "Parsed Place",
            address: "123 Main St, City",
            category: .food,
            dishes: ["Signature Dish"],
            priceRange: "$$",
            recommender: nil,
            confidence: 0.85
        )
    }

    func parseImage(_ imageData: Data) async throws -> ParsedPlaceResult {
        // TODO: Implement Claude Vision API call with base64 image
        return ParsedPlaceResult(
            placeName: "Parsed Place from Image",
            address: "456 Oak Ave, City",
            category: .cafe,
            dishes: [],
            priceRange: "$",
            recommender: nil,
            confidence: 0.75
        )
    }
}
