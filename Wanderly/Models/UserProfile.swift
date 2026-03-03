import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    var displayName: String
    var email: String?
    var avatarUrl: String?
    var savedCount: Int
    var visitedCount: Int
    var citiesCount: Int
    var isPremium: Bool
    var collections: [PlaceCollection]
    var createdAt: Date
}

struct PlaceCollection: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var placeIds: [UUID]
    var emoji: String
}

// MARK: - Mock Data

extension UserProfile {
    static let mock = UserProfile(
        id: UUID(),
        displayName: "Wanderly User",
        email: "user@example.com",
        avatarUrl: nil,
        savedCount: 42,
        visitedCount: 18,
        citiesCount: 7,
        isPremium: false,
        collections: PlaceCollection.mockList,
        createdAt: Date().addingTimeInterval(-86400 * 90)
    )
}

extension PlaceCollection {
    static let mockList: [PlaceCollection] = [
        PlaceCollection(id: UUID(), name: "Date Night", placeIds: [], emoji: "🌙"),
        PlaceCollection(id: UUID(), name: "Brunch Spots", placeIds: [], emoji: "🥞"),
        PlaceCollection(id: UUID(), name: "Hidden Gems", placeIds: [], emoji: "💎"),
    ]
}
