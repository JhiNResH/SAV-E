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
                            .stroke(Color.saveBerry, lineWidth: 3)
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

                HStack(spacing: 10) {
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
                        .padding(.vertical, 4)
                    }

                    Button(action: { showProfile = true }) {
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.saveNotebookPage)
                                .frame(width: 42, height: 42)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.saveCocoa.opacity(0.12), lineWidth: 1)
                                )

                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.saveCocoa)

                            if !viewModel.reviewCandidates.isEmpty {
                                Text("\(viewModel.reviewCandidates.count)")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.saveInk)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.saveHoney)
                                    .clipShape(Capsule())
                                    .offset(x: 6, y: -5)
                            }
                        }
                        .frame(width: 42, height: 42)
                    }
                    .accessibilityLabel("Open SAV-E Passport")
                }
                .padding(.leading, 12)
                .padding(.trailing, 10)
                .padding(.vertical, 8)
                .background(Color.saveNotebookPage.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.saveNotebookLine.opacity(0.60), lineWidth: 1.1)
                )
                .shadow(color: Color.saveCocoa.opacity(0.12), radius: 14, y: 6)
                .padding(.horizontal, 12)
                .padding(.top, geo.safeAreaInsets.top + 8)
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
                    .fill(Color.saveNotebookPage)
                    .frame(width: 54, height: 54)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.saveNotebookLine.opacity(0.72), lineWidth: 1.1)
                    )
                    .shadow(color: Color.saveCocoa.opacity(0.18), radius: 0, x: 3, y: 3)

                if isLocating {
                    ProgressView()
                        .tint(.saveBerry)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.saveBerry)
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
                    SaveEggBadge(state: .hatched(place.category), size: 42)

                    if place.status == .visited {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.saveBerry)
                            .background(Circle().fill(Color.saveNotebookPage))
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
