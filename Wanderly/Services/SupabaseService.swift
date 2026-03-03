import Foundation

// MARK: - Protocol

protocol SupabaseServiceProtocol {
    func fetchPlaces(for userId: String) async throws -> [Place]
    func savePlace(_ place: Place, userId: String) async throws
    func updatePlace(_ place: Place) async throws
    func deletePlace(_ placeId: UUID) async throws
    func fetchTrips(for userId: String) async throws -> [Trip]
    func saveTrip(_ trip: Trip, userId: String) async throws
    func updateTrip(_ trip: Trip) async throws
    func deleteTrip(_ tripId: UUID) async throws
    func fetchProfile(for userId: String) async throws -> UserProfile?
    func updateProfile(_ profile: UserProfile) async throws
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notConfigured
    case notAuthenticated
    case recordNotFound
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Supabase not configured"
        case .notAuthenticated: return "User not authenticated"
        case .recordNotFound: return "Record not found"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Stub Implementation

final class SupabaseService: SupabaseServiceProtocol {
    static let shared = SupabaseService()

    private let supabaseUrl: String?
    private let supabaseKey: String?

    init() {
        self.supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"]
        self.supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
    }

    func fetchPlaces(for userId: String) async throws -> [Place] {
        // TODO: Implement Supabase query
        // client.from("places").select().eq("user_id", userId)
        return Place.mockList
    }

    func savePlace(_ place: Place, userId: String) async throws {
        // TODO: Implement Supabase insert
    }

    func updatePlace(_ place: Place) async throws {
        // TODO: Implement Supabase update
    }

    func deletePlace(_ placeId: UUID) async throws {
        // TODO: Implement Supabase delete
    }

    func fetchTrips(for userId: String) async throws -> [Trip] {
        // TODO: Implement Supabase query
        return Trip.mockList
    }

    func saveTrip(_ trip: Trip, userId: String) async throws {
        // TODO: Implement Supabase insert
    }

    func updateTrip(_ trip: Trip) async throws {
        // TODO: Implement Supabase update
    }

    func deleteTrip(_ tripId: UUID) async throws {
        // TODO: Implement Supabase delete
    }

    func fetchProfile(for userId: String) async throws -> UserProfile? {
        // TODO: Implement Supabase query
        return UserProfile.mock
    }

    func updateProfile(_ profile: UserProfile) async throws {
        // TODO: Implement Supabase update
    }
}
