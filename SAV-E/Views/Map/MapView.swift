import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Map(position: $viewModel.cameraPosition, selection: $viewModel.selectedMapFeature) {
                    UserAnnotation()

                    ForEach(viewModel.filteredPlaces) { place in
                        Annotation("", coordinate: place.coordinate) {
                            PlaceMapPin(
                                place: place,
                                isSelected: viewModel.selectedPlace?.id == place.id
                            ) {
                                viewModel.selectPlace(place)
                            }
                        }
                    }

                    ForEach(viewModel.reviewCandidatesOnMap) { candidate in
                        if let coordinate = candidate.coordinate {
                            Annotation("", coordinate: coordinate) {
                                ReviewCandidateMapPin(
                                    candidate: candidate,
                                    isSelected: viewModel.selectedReviewCandidate?.id == candidate.id
                                ) {
                                    viewModel.selectReviewCandidate(candidate)
                                }
                            }
                        }
                    }

                    ForEach(viewModel.visibleMapCandidates) { candidate in
                        Annotation("", coordinate: candidate.coordinate) {
                            UnsavedMapCandidatePin(
                                candidate: candidate,
                                isSelected: viewModel.selectedMapCandidate?.id == candidate.id
                            ) {
                                viewModel.selectMapCandidate(candidate)
                            }
                        }
                    }

                    ForEach(viewModel.visibleSocialPlaces) { place in
                        Annotation("", coordinate: place.coordinate) {
                            SocialPlaceMapPin(
                                place: place,
                                isSelected: viewModel.selectedSocialPlace?.id == place.id
                            ) {
                                viewModel.selectSocialPlace(place)
                            }
                        }
                    }

                    if let polyline = viewModel.routePolyline {
                        MapPolyline(polyline)
                            .stroke(Color.saveCocoa, lineWidth: 3)
                    }
                }
                .mapStyle(.standard)
                .mapFeatureSelectionDisabled { feature in
                    feature.kind != .pointOfInterest
                }
                .mapControls {
                    MapCompass()
                }
                .onChange(of: viewModel.selectedMapFeature) { _, feature in
                    viewModel.selectMapFeature(feature)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CurrentLocationButton(
                            isLocating: viewModel.isLocatingUser,
                            action: {
                                Task { await viewModel.focusOnUserLocation() }
                            }
                        )
                        .padding(.trailing, 18)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom + 96, 112))
                    }
                }
            }
            .ignoresSafeArea()
        }
        .task {
            await viewModel.focusOnUserLocationOnLaunch()
        }
    }
}

private struct CurrentLocationButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let isLocating: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(controlFill)
                    .frame(width: 54, height: 54)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(controlStroke, lineWidth: 1)
                    )

                if isLocating {
                    ProgressView()
                        .tint(controlForeground)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(controlForeground)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLocating)
        .accessibilityLabel("Center map on current location")
        .accessibilityHint("Moves the map back to where you are now")
    }

    private var controlFill: Color {
        colorScheme == .dark ? Color.black.opacity(0.52) : Color.white.opacity(0.72)
    }

    private var controlStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.16) : Color.saveNotebookLine.opacity(0.26)
    }

    private var controlForeground: Color {
        colorScheme == .dark ? .white : .saveInk
    }
}

// MARK: - Map Pin

struct PlaceMapPin: View {
    let place: Place
    var isSelected = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            DefaultPOIMarker(
                systemName: place.category.iconName,
                tint: place.category.mapTint,
                isSelected: isSelected,
                showsSavedBadge: true
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(place.name) Map Stamp")
    }
}

private struct SocialPlaceMapPin: View {
    let place: Place
    var isSelected = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            DefaultPOIMarker(
                systemName: place.category.iconName,
                tint: place.category.mapTint,
                isSelected: isSelected,
                showsSavedBadge: true
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(place.name) social place")
        .accessibilityHint(place.socialSignal?.displayText ?? "Opens a place from your social map")
    }
}

private struct ReviewCandidateMapPin: View {
    let candidate: PlaceReviewCandidate
    var isSelected = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            DefaultPOIMarker(
                systemName: "doc.text.magnifyingglass",
                tint: .saveHoney,
                isSelected: isSelected,
                showsSavedBadge: false
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(candidate.name) Review Candidate")
        .accessibilityHint("Opens the Review Candidate before saving it as a Map Stamp")
    }
}

private struct UnsavedMapCandidatePin: View {
    let candidate: SaveMapCandidate
    var isSelected = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            DefaultPOIMarker(
                systemName: candidate.category?.iconName ?? "mappin.circle.fill",
                tint: candidate.category?.mapTint ?? .saveSky,
                isSelected: isSelected,
                showsSavedBadge: false
            )
        }
        .buttonStyle(.plain)
        .zIndex(isSelected ? 10 : 0)
        .accessibilityLabel("\(candidate.title) Unsaved Candidate")
        .accessibilityHint("Opens this visible map place before saving it as a Map Stamp")
    }
}

private struct DefaultPOIMarker: View {
    var systemName: String
    var tint: Color
    var isSelected: Bool
    var showsSavedBadge: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)
                .overlay(Circle().fill(tint.opacity(isSelected ? 0.24 : 0.16)))
                .overlay(
                    Circle()
                        .stroke(showsSavedBadge ? Color.saveSignal.opacity(0.72) : Color.white.opacity(0.86), lineWidth: isSelected ? 2.4 : 1.8)
                )
                .frame(width: isSelected ? 34 : 30, height: isSelected ? 34 : 30)

            Image(systemName: systemName)
                .font(.system(size: isSelected ? 17 : 15, weight: .bold))
                .foregroundStyle(tint)
        }
        .overlay(alignment: .bottomTrailing) {
            if showsSavedBadge {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: isSelected ? 11 : 10, weight: .black))
                    .foregroundStyle(Color.saveSignal)
                    .background(Circle().fill(Color.white.opacity(0.92)))
                    .offset(x: 2, y: 2)
            }
        }
        .shadow(color: Color.black.opacity(0.16), radius: isSelected ? 4 : 2, x: 0, y: 1)
        .scaleEffect(isSelected ? 1.06 : 1)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
        .contentShape(Rectangle())
    }
}

private extension PlaceCategory {
    var mapTint: Color {
        switch self {
        case .food: return .orange
        case .cafe: return .brown
        case .bar: return .purple
        case .attraction: return .pink
        case .stay: return .blue
        case .shopping: return .saveHoney
        }
    }
}

private extension PlaceReviewCandidate {
    var coordinate: CLLocationCoordinate2D? {
        guard hasReliableCoordinates, let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension SaveMapCandidate {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
