import Foundation

enum WanderlySharedStorage {
    static let appGroupSuiteName = "group.com.wanderly.app"
    static let pendingPlacesKey = "pendingPlaces"
}

struct PendingSharedPlace: Codable {
    var name: String
    var address: String
    var category: String
    var latitude: Double
    var longitude: Double
    var dishes: [String]
    var priceRange: String?
    var sourceURL: String?
    var sourceText: String?
    var savedAt: Date
}

final class PendingPlaceImportService {
    static let shared = PendingPlaceImportService()

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: WanderlySharedStorage.appGroupSuiteName)) {
        self.defaults = defaults
    }

    func consumePendingPlaces() -> [PendingSharedPlace] {
        guard let defaults else { return [] }
        let pending = loadPendingPlaces()
        defaults.removeObject(forKey: WanderlySharedStorage.pendingPlacesKey)
        return pending
    }

    func restorePendingPlaces(_ places: [PendingSharedPlace]) {
        guard !places.isEmpty else { return }
        let existing = loadPendingPlaces()
        save(existing + places)
    }

    private func loadPendingPlaces() -> [PendingSharedPlace] {
        guard let defaults else { return [] }
        guard let data = defaults.data(forKey: WanderlySharedStorage.pendingPlacesKey) else {
            return []
        }
        return (try? JSONDecoder().decode([PendingSharedPlace].self, from: data)) ?? []
    }

    private func save(_ places: [PendingSharedPlace]) {
        guard let defaults else { return }
        guard let data = try? JSONEncoder().encode(places) else { return }
        defaults.set(data, forKey: WanderlySharedStorage.pendingPlacesKey)
    }
}

extension Place {
    static func from(_ pendingPlace: PendingSharedPlace) -> Place {
        Place(
            id: UUID(),
            name: pendingPlace.name,
            address: pendingPlace.address,
            latitude: pendingPlace.latitude,
            longitude: pendingPlace.longitude,
            googlePlaceId: nil,
            category: PlaceCategory(rawValue: pendingPlace.category) ?? .food,
            status: .wantToGo,
            rating: nil,
            note: pendingPlace.sourceText,
            sourceUrl: pendingPlace.sourceURL,
            sourcePlatform: SourcePlatform.from(urlString: pendingPlace.sourceURL),
            sourceImageUrl: nil,
            extractedDishes: pendingPlace.dishes,
            priceRange: pendingPlace.priceRange,
            recommender: nil,
            googleRating: nil,
            googlePriceLevel: nil,
            openingHours: nil,
            createdAt: pendingPlace.savedAt
        )
    }

    var pendingDeduplicationKey: String {
        if let sourceUrl, !sourceUrl.isEmpty { return sourceUrl }
        return "\(name)|\(address)|\(createdAt.timeIntervalSince1970)"
    }

    func matches(_ pendingPlace: PendingSharedPlace) -> Bool {
        pendingDeduplicationKey == pendingPlace.deduplicationKey || (
            name == pendingPlace.name &&
            address == pendingPlace.address &&
            sourceUrl == pendingPlace.sourceURL
        )
    }

    func matches(_ other: Place) -> Bool {
        pendingDeduplicationKey == other.pendingDeduplicationKey || (
            name == other.name &&
            address == other.address &&
            sourceUrl == other.sourceUrl
        )
    }
}

extension PendingSharedPlace {
    var deduplicationKey: String {
        if let sourceURL, !sourceURL.isEmpty { return sourceURL }
        return "\(name)|\(address)|\(savedAt.timeIntervalSince1970)"
    }
}

extension SourcePlatform {
    static func from(urlString: String?) -> SourcePlatform {
        guard let url = urlString.flatMap(URL.init(string:)),
              let host = url.host()?.lowercased() else {
            return .other
        }
        if host.matchesDomain("instagram.com") { return .instagram }
        if host.matchesDomain("threads.net") || host.matchesDomain("threads.com") { return .threads }
        if host.matchesDomain("xiaohongshu.com") || host.matchesDomain("xhslink.com") { return .xiaohongshu }
        if host.isGoogleMapsHost(path: url.path.lowercased()) { return .googleMaps }
        return .other
    }
}

private extension String {
    func matchesDomain(_ domain: String) -> Bool {
        self == domain || hasSuffix(".\(domain)")
    }

    func isGoogleMapsHost(path: String) -> Bool {
        if self == "maps.google.com" {
            return true
        }

        if matchesDomain("google.com"), path.hasPrefix("/maps") {
            return true
        }

        return matchesDomain("maps.app.goo.gl") || matchesDomain("goo.gl") || matchesDomain("g.co")
    }
}
