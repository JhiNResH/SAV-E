import Foundation
import CoreLocation

/// Lightweight place payload encoded in the App Clip URL.
/// Duplicated in WanderlyClip target — keep in sync with main app's copy.
struct SharedPlaceData: Codable {
    let id: String
    let name: String
    let address: String
    let lat: Double
    let lng: Double
    let category: String
    let rating: Double?
    let reviewCount: Int?
    let priceRange: String?
    let hours: String?
    let sourceLabel: String
    let sourceURL: String?
    let photoURLs: [String]
    let note: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    static func from(url: URL) -> SharedPlaceData? {
        ShareRouteCodec.decode(SharedPlaceData.self, from: url, route: "p")
    }

    func toURL(baseURL: String = "https://sav-e.app/p") -> URL? {
        ShareRouteCodec.url(for: self, baseURL: baseURL)
    }
}

/// Lightweight trip payload encoded in the App Clip URL.
/// Duplicated in WanderlyClip target — keep in sync with main app's copy.
struct SharedTripData: Codable {
    let name: String
    let city: String
    let stops: [SharedStop]

    struct SharedStop: Codable, Identifiable {
        let id: String
        let name: String
        let address: String
        let lat: Double
        let lng: Double
        let time: String?
        let note: String?

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
    }

    // MARK: - URL Encoding

    /// Decode from a SAV-E route token, with legacy `?d=` support.
    static func from(url: URL) -> SharedTripData? {
        ShareRouteCodec.decode(SharedTripData.self, from: url, route: "trip")
    }

    /// Encode to a shareable URL.
    func toURL(baseURL: String = "https://sav-e.app/trip") -> URL? {
        ShareRouteCodec.url(for: self, baseURL: baseURL)
    }

    var routeSummary: String {
        let countLabel = stops.count == 1 ? "1 stop" : "\(stops.count) stops"
        guard !city.isEmpty else { return countLabel }
        return "\(countLabel) in \(city)"
    }
}

enum ShareRouteCodec {
    static func url<T: Encodable>(for payload: T, baseURL: String) -> URL? {
        guard let token = token(for: payload) else { return nil }
        return URL(string: "\(baseURL)/\(token)")
    }

    static func decode<T: Decodable>(_ type: T.Type, from url: URL, route: String) -> T? {
        guard let token = token(from: url, route: route),
              let data = data(from: token) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func token<T: Encodable>(for payload: T) -> String? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func data(from token: String) -> Data? {
        var base64 = token
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = base64.count % 4
        if padding > 0 {
            base64.append(String(repeating: "=", count: 4 - padding))
        }
        return Data(base64Encoded: base64)
    }

    private static func token(from url: URL, route: String) -> String? {
        let pathParts = url.path.split(separator: "/").map(String.init)
        if let routeIndex = pathParts.firstIndex(of: route),
           pathParts.indices.contains(routeIndex + 1) {
            return pathParts[routeIndex + 1]
        }
        if url.scheme == "wanderly", url.host == route {
            return pathParts.first ?? legacyQueryToken(from: url)
        }
        return legacyQueryToken(from: url)
    }

    private static func legacyQueryToken(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first(where: { $0.name == "d" })?
            .value
    }
}

struct SharedListPayload: Codable {
    var list: SharedListData
    var role: String

    static func from(url: URL) -> SharedListPayload? {
        guard isListLink(url),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let dataParam = components.queryItems?.first(where: { $0.name == "d" })?.value,
              let jsonData = Data(base64Encoded: dataParam),
              var payload = try? JSONDecoder().decode(SharedListPayload.self, from: jsonData) else {
            return nil
        }
        if let role = components.queryItems?.first(where: { $0.name == "r" })?.value {
            payload.role = role
            payload.list.viewerRole = role
        }
        return payload
    }

    static func isListLink(_ url: URL) -> Bool {
        if url.scheme == "wanderly", url.host == "list" {
            return true
        }
        return url.scheme == "https" &&
            url.host == "wanderly.app" &&
            url.path == "/list"
    }
}

struct SharedListData: Codable, Identifiable {
    let id: UUID
    let title: String
    let note: String?
    let ownerDisplayName: String
    var viewerRole: String
    let items: [SharedListItem]
    let createdAt: Date
    let updatedAt: Date

    var roleLabel: String {
        viewerRole.capitalized
    }
}

struct SharedListItem: Codable, Identifiable {
    let id: UUID
    let source: String
    let sourceID: String
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let category: String?
    let rating: Double?
    let reviewCount: Int?
    let sourceURL: String?
    let photoURLs: [String]
    let note: String?
    let addedByDisplayName: String
    let addedAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var sourceLabel: String {
        source == "savedPlace" ? "Map Stamp" : "Map result"
    }
}
