import Foundation
import MapKit

// MARK: - AI Response (domain model)

struct SaveAIResponse: Equatable {
    let componentType: ComponentType
    let title: String?
    let placeIds: [String]
    let navigationPlaceId: String?
    let transportMode: TransportMode
    let itineraryDays: [ItineraryDay]
    var tripHealth: TripHealth? = nil
    let messageText: String?
    let mapAction: MapActionData?
    let aiMessage: String?

    enum ComponentType: String, Codable, Equatable {
        case placeList, navigationCard, tripItinerary, message
    }

    enum TransportMode: String, Codable, Equatable, Hashable {
        case walking, transit, driving

        var mapsKey: String {
            switch self {
            case .walking: return MKLaunchOptionsDirectionsModeWalking
            case .transit: return MKLaunchOptionsDirectionsModeTransit
            case .driving: return MKLaunchOptionsDirectionsModeDriving
            }
        }
    }
}

// MARK: - Map Action

struct MapActionData: Codable, Equatable {
    let type: ActionType
    let placeIds: [String]?
    let lat: Double?
    let lng: Double?
    let span: Double?

    enum ActionType: String, Codable, Equatable {
        case filterPins, focusRegion, showRoute, resetPins
    }
}

// MARK: - Itinerary

struct ItineraryDay: Identifiable, Equatable {
    let dayNumber: Int
    let label: String?
    let stops: [ItineraryStop]
    var health: TripHealth? = nil
    var id: Int { dayNumber }
}

struct ItineraryStop: Identifiable, Equatable {
    let id: UUID
    let placeId: String?
    var placeState: ItineraryPlaceState? = nil
    let placeName: String
    let time: String?
    let duration: Int?
    let note: String?
    var sourceSummary: String? = nil
    var risks: [TripRisk] = []
}

enum ItineraryPlaceState: String, Codable, Equatable, Hashable {
    case sourceOnly
    case reviewCandidate
    case confirmedMapStamp
    case externalSuggestion
}

enum TripRisk: String, Codable, Equatable, Hashable {
    case hoursUnknown = "hours_unknown"
    case bookingUnknown = "booking_unknown"
    case needsReview = "needs_review"
    case externalSuggestion = "external_suggestion"
    case tooFarFromPrevious = "too_far_from_previous"
    case sourceWeak = "source_weak"
}

struct TripHealth: Codable, Equatable, Hashable {
    let score: Int
    let strengths: [String]
    let warnings: [TripWarning]
    let gaps: [TripGap]
}

struct TripWarning: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let type: WarningType
    let severity: Severity
    let message: String
    var affectedBlockIds: [String] = []

    enum WarningType: String, Codable, Equatable, Hashable {
        case tooManyStops = "too_many_stops"
        case tooManyAreas = "too_many_areas"
        case hoursUnknown = "hours_unknown"
        case bookingUnknown = "booking_unknown"
        case tooManyUnconfirmedPlaces = "too_many_unconfirmed_places"
        case lowMemoryCoverage = "low_memory_coverage"
        case notEnoughBuffer = "not_enough_buffer"
    }
}

struct TripGap: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let type: GapType
    let dayId: String
    var area: String? = nil
    let severity: Severity
    let message: String

    enum GapType: String, Codable, Equatable, Hashable {
        case missingBreakfast = "missing_breakfast"
        case missingLunch = "missing_lunch"
        case missingDinner = "missing_dinner"
        case missingCoffeeBreak = "missing_coffee_break"
        case missingAfternoonActivity = "missing_afternoon_activity"
        case missingEveningPlan = "missing_evening_plan"
        case needsAreaCluster = "needs_area_cluster"
        case needsRainBackup = "needs_rain_backup"
        case needsHoursCheck = "needs_hours_check"
    }
}

enum Severity: String, Codable, Equatable, Hashable {
    case low
    case medium
    case high
}

// MARK: - Codable DTOs (what Gemini actually returns)

struct SaveAIResponseDTO: Codable {
    let componentType: String
    let title: String?
    let placeIds: [String]?
    let navigationPlaceId: String?
    let transportMode: String?
    let itineraryDays: [ItineraryDayDTO]?
    let tripHealth: TripHealth?
    let messageText: String?
    let mapAction: MapActionData?
    let aiMessage: String?

    func toResponse() -> SaveAIResponse {
        SaveAIResponse(
            componentType: SaveAIResponse.ComponentType(rawValue: componentType) ?? .message,
            title: title,
            placeIds: placeIds ?? [],
            navigationPlaceId: navigationPlaceId,
            transportMode: SaveAIResponse.TransportMode(rawValue: transportMode ?? "walking") ?? .walking,
            itineraryDays: (itineraryDays ?? []).map { $0.toModel() },
            tripHealth: tripHealth,
            messageText: messageText,
            mapAction: mapAction,
            aiMessage: aiMessage
        )
    }
}

struct ItineraryDayDTO: Codable {
    let dayNumber: Int
    let label: String?
    let stops: [ItineraryStopDTO]
    let health: TripHealth?

    func toModel() -> ItineraryDay {
        ItineraryDay(dayNumber: dayNumber, label: label, stops: stops.map { $0.toModel() }, health: health)
    }
}

struct ItineraryStopDTO: Codable {
    let placeId: String?
    let placeState: ItineraryPlaceState?
    let placeName: String
    let time: String?
    let duration: Int?
    let note: String?
    let sourceSummary: String?
    let risks: [TripRisk]?

    func toModel() -> ItineraryStop {
        ItineraryStop(
            id: UUID(),
            placeId: placeId,
            placeState: placeState,
            placeName: placeName,
            time: time,
            duration: duration,
            note: note,
            sourceSummary: sourceSummary,
            risks: risks ?? []
        )
    }
}
