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
                    MapUserLocationButton()
                    MapCompass()
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
            ProfileView()
        }
        .task {
            await viewModel.loadPlaces()
            await viewModel.focusOnUserLocationOnLaunch()
        }
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
