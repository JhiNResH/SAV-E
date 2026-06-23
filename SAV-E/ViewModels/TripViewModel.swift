import Foundation

@MainActor
final class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = Trip.mockList
    @Published var selectedTrip: Trip?
    @Published var isOptimizing = false
    @Published var isLoading = false

    private let supabaseService: SupabaseServiceProtocol
    private let authService: PrivyAuthService

    init(supabaseService: SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabaseService = supabaseService
        self.authService = PrivyAuthService.shared
    }

    func loadTrips() async {
        guard let userId = authService.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            trips = try await supabaseService.fetchTrips(for: userId)
        } catch {
            print("Failed to load trips: \(error)")
        }
    }

    func createTrip(name: String, city: String) async {
        let trip = Trip(
            id: UUID(),
            name: name,
            city: city,
            startDate: nil,
            endDate: nil,
            places: [],
            isOptimized: false,
            createdAt: Date()
        )
        trips.append(trip)

        guard let userId = authService.currentUserId else { return }
        do {
            try await supabaseService.saveTrip(trip, userId: userId)
        } catch {
            print("Failed to save trip: \(error)")
        }
    }

    func optimizeRoute(for trip: Trip) async {
        isOptimizing = true
        defer { isOptimizing = false }

        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].places = Self.normalizedTimelineStops(trips[index].places)
            trips[index].isOptimized = true
        }
    }

    func deleteTrip(_ trip: Trip) async {
        trips.removeAll { $0.id == trip.id }
        do {
            try await supabaseService.deleteTrip(trip.id)
        } catch {
            print("Failed to delete trip: \(error)")
        }
    }

    func reorderStops(trip: Trip, from: IndexSet, to: Int) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[tripIndex].places.move(fromOffsets: from, toOffset: to)
        // Update orderIndex values
        for i in trips[tripIndex].places.indices {
            trips[tripIndex].places[i].orderIndex = i
        }
    }

    static func normalizedTimelineStops(_ stops: [TripStop]) -> [TripStop] {
        let sorted = stops.sorted {
            if $0.day != $1.day { return $0.day < $1.day }
            if $0.orderIndex != $1.orderIndex { return $0.orderIndex < $1.orderIndex }
            return $0.placeName.localizedCaseInsensitiveCompare($1.placeName) == .orderedAscending
        }

        var nextIndexByDay: [Int: Int] = [:]
        return sorted.map { stop in
            var updated = stop
            let nextIndex = nextIndexByDay[stop.day, default: 0]
            updated.orderIndex = nextIndex
            nextIndexByDay[stop.day] = nextIndex + 1
            return updated
        }
    }
}
