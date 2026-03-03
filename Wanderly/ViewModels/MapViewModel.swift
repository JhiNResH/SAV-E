import Foundation
import MapKit
import SwiftUI

@MainActor
final class MapViewModel: ObservableObject {
    @Published var places: [Place] = Place.mockList
    @Published var selectedPlace: Place?
    @Published var showBottomSheet = false
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var selectedCategories: Set<PlaceCategory> = []
    @Published var isLoading = false

    private let supabaseService: SupabaseServiceProtocol
    private let authService: PrivyAuthService

    init(
        supabaseService: SupabaseServiceProtocol = SupabaseService.shared,
        authService: PrivyAuthService = .shared
    ) {
        self.supabaseService = supabaseService
        self.authService = authService
    }

    var filteredPlaces: [Place] {
        if selectedCategories.isEmpty { return places }
        return places.filter { selectedCategories.contains($0.category) }
    }

    func loadPlaces() async {
        guard let userId = authService.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            places = try await supabaseService.fetchPlaces(for: userId)
        } catch {
            // TODO: Handle error
            print("Failed to load places: \(error)")
        }
    }

    func selectPlace(_ place: Place) {
        selectedPlace = place
        showBottomSheet = true
        region = MKCoordinateRegion(
            center: place.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    func toggleCategory(_ category: PlaceCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}
