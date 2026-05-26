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

                    if let polyline = viewModel.routePolyline {
                        MapPolyline(polyline)
                            .stroke(Color.saveCocoa, lineWidth: 3)
                    }
                }
                .mapStyle(.standard)
                .mapControls {
                    MapCompass()
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    Task {
                        await viewModel.refreshMapCandidates(
                            near: context.region.center,
                            span: context.region.span
                        )
                    }
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

                TopNotebookNavBar(
                    selectedCategories: viewModel.selectedCategories,
                    reviewCount: viewModel.reviewCandidates.count,
                    onToggleCategory: { category in
                        viewModel.toggleCategory(category)
                    },
                    onOpenProfile: {
                        showProfile = true
                    }
                )
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

private struct TopNotebookNavBar: View {
    let selectedCategories: Set<PlaceCategory>
    let reviewCount: Int
    let onToggleCategory: (PlaceCategory) -> Void
    let onOpenProfile: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            HStack(spacing: 6) {
                MemoMascotMark(size: 24, framed: false)
                Text("SAV-E")
                    .font(.caption.weight(.black))
                    .lineLimit(1)
            }
            .foregroundColor(.saveInk)
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(Color.saveCream.opacity(0.98))
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Color.saveNotebookLine, lineWidth: 1.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .accessibilityHidden(true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(PlaceCategory.allCases, id: \.self) { category in
                        CategoryPill(
                            category: category,
                            isSelected: selectedCategories.contains(category)
                        )
                        .onTapGesture { onToggleCategory(category) }
                    }
                }
                .padding(.vertical, 2)
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.04),
                        .init(color: .black, location: 0.94),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )

            PassportNavButton(reviewCount: reviewCount, action: onOpenProfile)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color.saveNotebookPage.opacity(0.96))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.saveNotebookLine, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct PassportNavButton: View {
    let reviewCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color.saveCream)
                    .frame(width: 42, height: 38)
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(Color.saveNotebookLine, lineWidth: 1.6)
                    )

                Image(systemName: "person.crop.circle")
                    .font(.system(size: 21, weight: .black))
                    .foregroundColor(.saveInk)

                if reviewCount > 0 {
                    Text("\(reviewCount)")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.saveInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.saveHoney)
                        .overlay(Capsule().stroke(Color.saveNotebookLine, lineWidth: 1))
                        .clipShape(Capsule())
                        .frame(maxWidth: 24)
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 42, height: 38)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open SAV-E Passport")
        .accessibilityValue(reviewCount > 0 ? "\(reviewCount) waiting clues" : "No waiting clues")
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
                            .stroke(Color.saveNotebookLine, lineWidth: 2)
                    )

                if isLocating {
                    ProgressView()
                        .tint(.saveInk)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.saveInk)
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
    var isSelected = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: -2) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(Color.saveHoney)
                            .frame(width: isSelected ? 52 : 46, height: isSelected ? 52 : 46)
                            .overlay(
                                Circle()
                                    .fill(Color.saveCream)
                                    .padding(isSelected ? 6 : 5)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.saveNotebookLine, lineWidth: isSelected ? 3 : 2)
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        Color.saveNotebookLine.opacity(0.42),
                                        style: StrokeStyle(lineWidth: 1.2, dash: [3, 3])
                                    )
                                    .padding(isSelected ? 10 : 9)
                            )
                            .shadow(color: Color.saveCocoa.opacity(isSelected ? 0.28 : 0.16), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 5 : 3)

                        Image(systemName: place.category.iconName)
                            .font(.system(size: isSelected ? 21 : 18, weight: .black))
                            .foregroundColor(.saveInk)

                        Text("S")
                            .font(.system(size: isSelected ? 8 : 7, weight: .black, design: .rounded))
                            .foregroundColor(.saveInk)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.saveCream)
                            .overlay(Capsule().stroke(Color.saveNotebookLine, lineWidth: 1))
                            .clipShape(Capsule())
                            .offset(x: isSelected ? 16 : 14, y: isSelected ? 16 : 14)
                    }

                    if place.status == .visited {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.saveSignal)
                            .background(Circle().fill(Color.saveNotebookPage))
                            .offset(x: 5, y: -5)
                    }
                }

                Image(systemName: "triangle.fill")
                    .font(.system(size: isSelected ? 10 : 8))
                    .foregroundColor(.saveCocoa)
                    .rotationEffect(.degrees(180))
                    .offset(y: -1)
            }
            .scaleEffect(isSelected ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(place.name) Map Stamp")
    }
}

private struct ReviewCandidateMapPin: View {
    let candidate: PlaceReviewCandidate
    var isSelected = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: -2) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.saveSky)
                        .frame(width: isSelected ? 50 : 44, height: isSelected ? 50 : 44)
                        .overlay(
                            Circle()
                                .fill(Color.saveNotebookPage)
                                .padding(isSelected ? 6 : 5)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.saveNotebookLine, lineWidth: isSelected ? 3 : 2)
                        )
                        .overlay(
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: isSelected ? 18 : 16, weight: .black))
                                .foregroundColor(.saveInk)
                        )
                        .shadow(color: Color.saveCocoa.opacity(isSelected ? 0.24 : 0.14), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 5 : 3)

                    Text("?")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundColor(.saveInk)
                        .frame(width: 17, height: 17)
                        .background(Color.saveHoney)
                        .overlay(Circle().stroke(Color.saveNotebookLine, lineWidth: 1))
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }

                Image(systemName: "triangle.fill")
                    .font(.system(size: isSelected ? 10 : 8))
                    .foregroundColor(.saveCocoa)
                    .rotationEffect(.degrees(180))
                    .offset(y: -1)
            }
            .scaleEffect(isSelected ? 1.06 : 1)
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
            VStack(spacing: -2) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.saveSignal)
                        .frame(width: isSelected ? 48 : 42, height: isSelected ? 48 : 42)
                        .overlay(
                            Circle()
                                .fill(Color.saveCream)
                                .padding(isSelected ? 6 : 5)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.saveNotebookLine, lineWidth: isSelected ? 3 : 2)
                        )
                        .overlay(
                            Image(systemName: candidate.category?.iconName ?? "mappin.and.ellipse")
                                .font(.system(size: isSelected ? 18 : 15, weight: .black))
                                .foregroundColor(.saveInk)
                        )
                        .shadow(color: Color.saveCocoa.opacity(isSelected ? 0.24 : 0.14), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 5 : 3)

                    Text("+")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundColor(.saveInk)
                        .frame(width: 17, height: 17)
                        .background(Color.saveSky)
                        .overlay(Circle().stroke(Color.saveNotebookLine, lineWidth: 1))
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }

                Image(systemName: "triangle.fill")
                    .font(.system(size: isSelected ? 10 : 8))
                    .foregroundColor(.saveCocoa)
                    .rotationEffect(.degrees(180))
                    .offset(y: -1)
            }
            .scaleEffect(isSelected ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(candidate.title) Unsaved Candidate")
        .accessibilityHint("Opens this visible map place before saving it as a Map Stamp")
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
