import Foundation
import CoreLocation

// MARK: - Place

struct Place: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var googlePlaceId: String?
    var category: PlaceCategory
    var status: PlaceStatus
    var rating: Double?
    var note: String?
    var sourceUrl: String?
    var sourcePlatform: SourcePlatform
    var sourceImageUrl: String?
    var businessPhotoUrls: [String]? = nil
    var extractedDishes: [String]?
    var priceRange: String?
    var recommender: String?
    var googleRating: Double?
    var googlePriceLevel: Int?
    var openingHours: String?
    var createdAt: Date
    var visibility: PlaceVisibility? = nil
    var socialSignal: PlaceSocialSignal? = nil

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var sourceEvidence: [String] {
        var evidence: [String] = []
        if let sourceUrl = sourceUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !sourceUrl.isEmpty {
            evidence.append("Source URL: \(sourceUrl)")
        }
        if let recommender = recommender?.trimmingCharacters(in: .whitespacesAndNewlines),
           !recommender.isEmpty {
            evidence.append("Recommender: \(recommender)")
        }
        if let note {
            evidence += note
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return evidence.removingDuplicates()
    }

    var primarySourceURL: URL? {
        if let sourceUrl = normalizedSourceURL(from: sourceUrl) {
            return sourceUrl
        }
        return sourceEvidence
            .flatMap(Self.urls)
            .first
    }

    var shareSubject: String {
        "SAV-E Map Stamp: \(name)"
    }

    var saveShareURL: URL? {
        SharedTripData.from(place: self).toURL()
    }

    var shareText: String {
        var lines = [
            "SAV-E Map Stamp",
            name,
            address,
            "Category: \(category.displayName)",
            "Status: \(status.memoryCardLabel)"
        ]

        if let rating = googleRating ?? rating {
            lines.append("Rating: \(String(format: "%.1f", rating))")
        }
        if let priceRange, !priceRange.isEmpty {
            lines.append("Price: \(priceRange)")
        }
        if let recommender, !recommender.isEmpty {
            lines.append("Recommended by: \(recommender)")
        }
        if let note = note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
            lines.append("Note: \(note)")
        }
        if let sourceURL = primarySourceURL {
            lines.append("Source: \(sourceURL.absoluteString)")
        }
        if let saveShareURL {
            lines.append("Open in SAV-E: \(saveShareURL.absoluteString)")
        }
        if let mapsURL = appleMapsURL {
            lines.append("Map fallback: \(mapsURL.absoluteString)")
        }

        return lines.joined(separator: "\n")
    }

    var shareMessage: String {
        var parts = [address, category.displayName]
        if let rating = googleRating ?? rating {
            parts.append(String(format: "%.1f stars", rating))
        }
        return parts.joined(separator: " · ")
    }

    var shareAreaLabel: String {
        let parts = address
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if parts.count >= 2 { return parts[parts.count - 2] }
        return parts.first ?? ""
    }

    var appleMapsURL: URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "ll", value: "\(latitude),\(longitude)")
        ]
        return components?.url
    }

    func matchesMapFeature(title: String, coordinate: CLLocationCoordinate2D) -> Bool {
        let distance = CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        guard distance < 120 else { return false }

        let featureName = title.normalizedMapMatchText
        let placeName = name.normalizedMapMatchText
        let sameName = !featureName.isEmpty &&
            (featureName == placeName ||
             featureName.contains(placeName) ||
             placeName.contains(featureName))

        return sameName || distance < 20
    }

    var businessPhotoURLStrings: [String] {
        var values = businessPhotoUrls ?? []
        if let sourceImageUrl {
            values.insert(sourceImageUrl, at: 0)
        }
        return values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .removingDuplicates()
    }

    private func normalizedSourceURL(from rawValue: String?) -> URL? {
        guard let raw = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty
        else { return nil }

        if let url = URL(string: raw), url.scheme != nil {
            return url
        }

        return URL(string: "https://\(raw)")
    }

    private static func urls(in text: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector
            .matches(in: text, options: [], range: range)
            .compactMap(\.url)
            .filter { url in
                guard let scheme = url.scheme?.lowercased() else { return false }
                return scheme == "http" || scheme == "https"
            }
    }
}

private extension Array where Element == String {
    func removingDuplicates() -> [String] {
        var seen: Set<String> = []
        return filter { seen.insert($0).inserted }
    }
}

private extension String {
    var normalizedMapMatchText: String {
        folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

// MARK: - Enums

enum PlaceCategory: String, Codable, CaseIterable, Hashable {
    case food, cafe, bar, attraction, stay, shopping

    var displayName: String {
        switch self {
        case .food: return "Food"
        case .cafe: return "Cafe"
        case .bar: return "Bar"
        case .attraction: return "Attraction"
        case .stay: return "Stay"
        case .shopping: return "Shopping"
        }
    }

    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .bar: return "wineglass.fill"
        case .attraction: return "star.fill"
        case .stay: return "bed.double.fill"
        case .shopping: return "bag.fill"
        }
    }
}

enum PlaceStatus: String, Codable, Hashable {
    case wantToGo, visited

    var displayName: String {
        switch self {
        case .wantToGo: return "Want to Go"
        case .visited: return "Visited"
        }
    }

    var memoryCardLabel: String {
        switch self {
        case .wantToGo: return "Map Stamp"
        case .visited: return "Visited"
        }
    }
}

enum SourcePlatform: String, Codable, CaseIterable, Hashable {
    case instagram, threads, xiaohongshu, googleMaps, other

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .threads: return "Threads"
        case .xiaohongshu: return "Xiaohongshu"
        case .googleMaps: return "Google Maps"
        case .other: return "Other"
        }
    }
}

// MARK: - Mock Data

extension Place {
    static let mock = Place(
        id: UUID(),
        name: "Tartine Bakery",
        address: "600 Guerrero St, San Francisco, CA",
        latitude: 37.7614,
        longitude: -122.4241,
        googlePlaceId: "ChIJAQAAMal-j4ARm6sMODkLP28",
        category: .cafe,
        status: .wantToGo,
        rating: 4.5,
        note: "Must try the morning bun!",
        sourceUrl: "https://instagram.com/p/example",
        sourcePlatform: .instagram,
        sourceImageUrl: nil,
        extractedDishes: ["Morning Bun", "Country Bread"],
        priceRange: "$$",
        recommender: "@foodie_friend",
        googleRating: 4.6,
        googlePriceLevel: 2,
        openingHours: "Mon-Sun 8:00 AM - 5:00 PM",
        createdAt: Date(),
        visibility: .privateMemory,
        socialSignal: nil
    )

    static let mockList: [Place] = [
        .mock,
        Place(
            id: UUID(),
            name: "Ramen Nagi",
            address: "541 Valencia St, San Francisco, CA",
            latitude: 37.7642,
            longitude: -122.4214,
            category: .food,
            status: .visited,
            rating: 4.8,
            note: "Black King ramen is incredible",
            sourcePlatform: .threads,
            extractedDishes: ["Black King Ramen"],
            priceRange: "$$",
            googleRating: 4.5,
            createdAt: Date().addingTimeInterval(-86400),
            visibility: .privateMemory,
            socialSignal: nil
        ),
        Place(
            id: UUID(),
            name: "The Interval",
            address: "2 Marina Blvd, San Francisco, CA",
            latitude: 37.8064,
            longitude: -122.4090,
            category: .bar,
            status: .wantToGo,
            sourcePlatform: .other,
            priceRange: "$$$",
            googleRating: 4.3,
            createdAt: Date().addingTimeInterval(-172800),
            visibility: .privateMemory,
            socialSignal: nil
        ),
    ]

    static func socialSignalSeeds(near places: [Place]) -> [Place] {
        let anchor = places.first ?? .mock
        let baseLatitude = anchor.latitude == 0 ? 33.7455 : anchor.latitude
        let baseLongitude = anchor.longitude == 0 ? -117.8677 : anchor.longitude

        return [
            Place(
                id: UUID(),
                name: "Hidden House Coffee",
                address: "511 E Santa Ana Blvd, Santa Ana, CA",
                latitude: baseLatitude + 0.006,
                longitude: baseLongitude - 0.006,
                category: .cafe,
                status: .wantToGo,
                rating: 4.6,
                note: "Friend signal candidate",
                sourcePlatform: .other,
                priceRange: "$$",
                recommender: "Maya",
                googleRating: 4.6,
                createdAt: Date(),
                visibility: .friends,
                socialSignal: PlaceSocialSignal(
                    kind: .friendSaved,
                    lens: .friends,
                    friendNames: ["Maya", "Ezven"],
                    friendCount: 4,
                    saveCount: 18,
                    trendingRank: nil,
                    categoryRank: 2,
                    sourceLabel: "Friends",
                    referrerId: nil,
                    referralCode: nil
                )
            ),
            Place(
                id: UUID(),
                name: "Brodard Chateau",
                address: "9100 Trask Ave, Garden Grove, CA",
                latitude: baseLatitude - 0.005,
                longitude: baseLongitude + 0.007,
                category: .food,
                status: .wantToGo,
                rating: 4.5,
                note: "Trending food candidate",
                sourcePlatform: .other,
                priceRange: "$$",
                recommender: "SAV-E trending",
                googleRating: 4.5,
                createdAt: Date(),
                visibility: .publicGuide,
                socialSignal: PlaceSocialSignal(
                    kind: .trending,
                    lens: .trending,
                    friendNames: [],
                    friendCount: 0,
                    saveCount: 67,
                    trendingRank: 3,
                    categoryRank: 1,
                    sourceLabel: "Trending",
                    referrerId: nil,
                    referralCode: nil
                )
            ),
            Place(
                id: UUID(),
                name: "The Blind Rabbit",
                address: "440 S Anaheim Blvd, Anaheim, CA",
                latitude: baseLatitude + 0.004,
                longitude: baseLongitude + 0.005,
                category: .bar,
                status: .wantToGo,
                rating: 4.4,
                note: "For You candidate from friends and trending overlap",
                sourcePlatform: .other,
                priceRange: "$$$",
                recommender: "Maya",
                googleRating: 4.4,
                createdAt: Date(),
                visibility: .friends,
                socialSignal: PlaceSocialSignal(
                    kind: .friendSaved,
                    lens: .forYou,
                    friendNames: ["Maya"],
                    friendCount: 2,
                    saveCount: 24,
                    trendingRank: 8,
                    categoryRank: 3,
                    sourceLabel: "For You",
                    referrerId: nil,
                    referralCode: nil
                )
            ),
        ]
    }
}
