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
            DefaultMapPin(
                systemImage: place.category.iconName,
                fill: place.socialSignal?.pinFill ?? (place.status == .visited ? .saveMint : .saveHoney),
                sourceImage: place.socialSignal?.kind.pinSystemImage,
                isSelected: isSelected
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
            DefaultMapPin(
                systemImage: place.category.iconName,
                fill: place.socialSignal?.pinFill ?? .saveSignal,
                sourceImage: place.socialSignal?.kind.pinSystemImage,
                isSelected: isSelected
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
            DefaultMapPin(systemImage: "doc.text.magnifyingglass", fill: .saveSky, isSelected: isSelected)
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
            VStack(spacing: 3) {
                if isSelected {
                    Text(candidate.title)
                        .font(.caption2.weight(.black))
                        .foregroundColor(.saveInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: 132)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.saveNotebookPage.opacity(0.94))
                        .overlay(Capsule().stroke(Color.saveSignal, lineWidth: 1.5))
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
                }

                DefaultMapPin(
                    systemImage: candidate.category?.iconName ?? "mappin.and.ellipse",
                    fill: .saveSignal,
                    isSelected: isSelected
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(candidate.title) Unsaved Candidate")
        .accessibilityHint("Opens this visible map place before saving it as a Map Stamp")
    }
}

private struct DefaultMapPin: View {
    var systemImage: String
    var fill: Color
    var sourceImage: String? = nil
    var isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(fill.opacity(isSelected ? 1 : 0.92))
                .frame(width: isSelected ? 36 : 20, height: isSelected ? 36 : 20)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isSelected ? 0.95 : 0.35), lineWidth: isSelected ? 2.5 : 1)
                )
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.10), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(isSelected ? 0.30 : 0.10), radius: isSelected ? 8 : 2, x: 0, y: isSelected ? 4 : 1)

            Image(systemName: systemImage)
                .font(.system(size: isSelected ? 15 : 8, weight: .black))
                .foregroundColor(.white)

            if let sourceImage {
                Image(systemName: sourceImage)
                    .font(.system(size: 6, weight: .black))
                    .foregroundColor(.saveInk)
                    .frame(width: 12, height: 12)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Circle())
                    .offset(x: 11, y: -10)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                            .offset(x: 11, y: -10)
                    )
            }
        }
        .overlay {
            if isSelected {
                Circle()
                    .stroke(fill.opacity(0.35), lineWidth: 8)
                    .frame(width: 52, height: 52)
            }
        }
        .frame(width: isSelected ? 64 : 32, height: isSelected ? 64 : 32)
        .contentShape(Rectangle())
    }
}

private extension PlaceSocialSignal {
    var pinFill: Color {
        switch kind {
        case .friendSaved: return .saveSky
        case .trending: return .saveSignal
        case .referralGuide: return .savePink
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
