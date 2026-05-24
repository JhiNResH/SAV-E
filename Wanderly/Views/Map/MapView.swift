import SwiftUI
import MapKit

struct MapView: View {
    @State private var showProfile = false
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Map(position: $viewModel.cameraPosition) {
                    UserAnnotation()

                    ForEach(viewModel.filteredPlaces) { place in
                        Annotation("", coordinate: place.coordinate) {
                            PlaceMapPin(place: place) {
                                viewModel.selectPlace(place)
                            }
                        }
                    }
                    if let polyline = viewModel.routePolyline {
                        MapPolyline(polyline)
                            .stroke(Color.wanderlyTerracotta, lineWidth: 3)
                    }
                }
                .mapControls {
                    MapCompass()
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

                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PlaceCategory.allCases, id: \.self) { category in
                                CategoryPill(
                                    category: category,
                                    isSelected: viewModel.selectedCategories.contains(category)
                                )
                                .onTapGesture { viewModel.toggleCategory(category) }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.wanderlyTerracotta)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                            )
                    }
                    .padding(.trailing, 16)
                }
                .background(.ultraThinMaterial)
                .padding(.top, geo.safeAreaInsets.top)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(waitingClues: viewModel.reviewCandidates.count)
        }
        .task {
            await viewModel.focusOnUserLocationOnLaunch()
        }
    }
}

private struct CurrentLocationButton: View {
    let isLocating: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.saveCard)
                    .frame(width: 54, height: 54)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.85), lineWidth: 1)
                    )
                    .shadow(color: Color.saveCocoa.opacity(0.18), radius: 12, y: 6)

                if isLocating {
                    ProgressView()
                        .tint(.wanderlyTerracotta)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.wanderlyTerracotta)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLocating)
        .accessibilityLabel("Center map on current location")
        .accessibilityHint("Moves the map back to where you are now")
    }
}

// MARK: - Map Pin

struct PlaceMapPin: View {
    let place: Place
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: place.category.iconName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.saveStampForeground(for: place.category))
                        .frame(width: 38, height: 38)
                        .background(Color.saveStampColor(for: place.category))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                        )
                        .shadow(color: Color.saveCocoa.opacity(0.20), radius: 5, y: 3)

                    if place.status == .visited {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.saveBerry)
                            .background(Circle().fill(Color.white))
                            .offset(x: 5, y: -5)
                    }
                }

                Image(systemName: "triangle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(Color.saveStampColor(for: place.category))
                    .rotationEffect(.degrees(180))
                    .offset(y: -2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(place.name) map stamp")
    }
}
