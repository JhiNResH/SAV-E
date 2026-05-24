import SwiftUI

struct PlaceListView: View {
    @StateObject private var viewModel = PlaceListViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var loadPlacesTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 7) {
                    ForEach(PlaceFilter.allCases, id: \.self) { filter in
                        FilterNotebookTab(
                            title: filter.rawValue,
                            isSelected: viewModel.filter == filter
                        ) {
                            viewModel.filter = filter
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // Category pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PlaceCategory.allCases, id: \.self) { category in
                            CategoryPill(
                                category: category,
                                isSelected: viewModel.selectedCategories.contains(category)
                            )
                            .onTapGesture {
                                if viewModel.selectedCategories.contains(category) {
                                    viewModel.selectedCategories.remove(category)
                                } else {
                                    viewModel.selectedCategories.insert(category)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Sort selector
                HStack {
                    Text("\(viewModel.filteredPlaces.count) memory cards")
                        .font(.caption)
                        .foregroundColor(.saveMutedText)

                    Spacer()

                    Menu {
                        ForEach(PlaceSort.allCases, id: \.self) { sort in
                            Button(action: { viewModel.sort = sort }) {
                                Label(sort.rawValue, systemImage: viewModel.sort == sort ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.sort.rawValue)
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.saveCocoa)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)

                // List
                if viewModel.filteredPlaces.isEmpty {
                    EmptyStateView(
                        icon: "mappin.slash",
                        title: "No Memory Cards Found",
                        subtitle: "Try adjusting filters or save a Review clue as a memory card."
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredPlaces) { place in
                            NavigationLink(value: place) {
                                PlaceCard(place: place)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .leading) {
                                Button {
                                    Task { await viewModel.markVisited(place) }
                                } label: {
                                    Label("Visited", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.saveSuccess)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task { try? await viewModel.deletePlace(place) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(SaveDottedBackground())
                }

                if let deleteError = viewModel.deleteError {
                    Text(deleteError)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .background(SaveDottedBackground())
            .navigationTitle("Memory Cards")
            .searchable(text: $viewModel.searchText, prompt: "Search memory cards...")
            .navigationDestination(for: Place.self) { place in
                PlaceDetailView(place: place) {
                    try await viewModel.deletePlace(place)
                }
            }
        }
        .task {
            startLoadPlacesTask()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            startLoadPlacesTask()
        }
        .onDisappear {
            loadPlacesTask?.cancel()
            loadPlacesTask = nil
        }
    }

    private func startLoadPlacesTask() {
        loadPlacesTask?.cancel()
        loadPlacesTask = Task {
            await viewModel.loadPlaces()
        }
    }
}

private struct FilterNotebookTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundColor(.saveInk)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(isSelected ? Color.saveHoney : Color.saveNotebookPage)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.saveNotebookLine, lineWidth: isSelected ? 1.8 : 1.2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

#Preview {
    PlaceListView()
}
