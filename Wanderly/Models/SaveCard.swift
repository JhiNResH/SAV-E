import Foundation

struct SaveCard: Codable, Hashable, Identifiable {
    static let schemaVersion = "save.card.v0"

    var schema: String
    var cardType: SaveCardType
    var id: String
    var title: String
    var createdAt: Date
    var createdBy: String
    var visibility: SaveCardVisibility
    var source: SaveCardSource
    var places: [SaveCardPlace]
    var humanSummary: String
    var agentInstructions: [String]
    var redactions: [SaveCardRedaction]
    var actions: [SaveCardAction]

    var isValidSchema: Bool {
        schema == Self.schemaVersion
    }
}

enum SaveCardType: String, Codable, Hashable {
    case placeCard = "place_card"
    case recommendationCard = "recommendation_card"
    case itineraryCard = "itinerary_card"
    case reviewCard = "review_card"
}

enum SaveCardVisibility: String, Codable, Hashable {
    case `private`
    case publicLink = "public_link"
    case friends
    case agentReadable = "agent_readable"
}

struct SaveCardSource: Codable, Hashable {
    var kind: SaveCardSourceKind
    var url: String?
}

enum SaveCardSourceKind: String, Codable, Hashable {
    case instagram
    case luma
    case googleMaps = "google_maps"
    case appleMaps = "apple_maps"
    case manual
    case other
}

struct SaveCardPlace: Codable, Hashable {
    var name: String
    var address: String
    var geo: SaveCardGeo?
    var status: SaveCardPlaceStatus
    var confidence: Double?
    var proofLevel: SaveCardProofLevel
    var evidence: [String]
    var missingInfo: [String]
}

struct SaveCardGeo: Codable, Hashable {
    var latitude: Double
    var longitude: Double
}

enum SaveCardPlaceStatus: String, Codable, Hashable {
    case sourceOnly = "source_only"
    case reviewCandidate = "review_candidate"
    case confirmedPlace = "confirmed_place"
    case visited
}

enum SaveCardProofLevel: String, Codable, Hashable {
    case sourceLink = "source_link"
    case mapConfirmed = "map_confirmed"
    case visited
    case receiptBacked = "receipt_backed"
    case paymentBacked = "payment_backed"
}

struct SaveCardRedaction: Codable, Hashable {
    var field: String
    var reason: String
}

enum SaveCardAction: String, Codable, Hashable {
    case save
    case openMaps = "open_maps"
    case askAgent = "ask_agent"
    case `import`
}
