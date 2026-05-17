import SwiftUI
import UIKit

struct AIDrawerView: View {
    @ObservedObject var viewModel: AIDrawerViewModel
    @Binding var drawerDetent: PresentationDetent
    var existingPlacesForImport: [Place] = []
    var reviewCandidates: [PlaceReviewCandidate] = []
    var onSaveGoogleTakeoutImport: ([ImportedPlaceDraft]) async throws -> GoogleTakeoutSaveSummary = { _ in
        GoogleTakeoutSaveSummary(saved: 0, skippedDuplicates: 0, reviewDrafts: 0)
    }
    var onDeletePlace: (Place) async throws -> Void = { _ in }
    var onConfirmCandidate: (PlaceReviewCandidate) async throws -> Void = { _ in }
    var onRejectCandidate: (PlaceReviewCandidate) async throws -> Void = { _ in }
    var onSaveCandidate: (PlaceReviewCandidate) async throws -> Void = { _ in }
    @FocusState private var searchFocused: Bool
    @State private var showGoogleTakeoutImport = false
    @State private var addSpotStatus: String?
    @State private var candidateActionInFlight: UUID?

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            if showsContentArea {
                Divider()
                contentArea
            }
        }
        .background(Color.wanderlyCream)
        .sheet(isPresented: $viewModel.showPlaceList) {
            PlaceListView()
        }
        .sheet(isPresented: $showGoogleTakeoutImport) {
            GoogleTakeoutImportView(
                existingPlaces: existingPlacesForImport,
                onSave: onSaveGoogleTakeoutImport
            )
        }
        .onChange(of: viewModel.drawerState) { _, state in
            withAnimation(.spring(duration: 0.3)) {
                switch state {
                case .idle:             drawerDetent = .height(72)
                case .loading:          drawerDetent = .medium
                case .error:            drawerDetent = .medium
                case .placeDetail:      drawerDetent = .medium
                case .displaying(let r):
                    drawerDetent = r.componentType == .tripItinerary ? .large : .medium
                }
            }
        }
        .onChange(of: drawerDetent) { _, detent in
            guard case .idle = viewModel.drawerState else { return }
            if detent != .height(72) {
                searchFocused = true
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: isLoading ? "hourglass" : "sparkles")
                .foregroundColor(.wanderlyTerracotta)
                .font(.subheadline)
                .symbolEffect(.pulse, isActive: isLoading)

            TextField("Ask about your places...", text: $viewModel.query)
                .font(.subheadline)
                .foregroundColor(.wanderlyCharcoal)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { Task { await viewModel.submit() } }
                .onTapGesture {
                    withAnimation { drawerDetent = .medium }
                }

            if isLoading {
                ProgressView().tint(.wanderlyTerracotta).scaleEffect(0.8)
            } else if !viewModel.query.isEmpty {
                Button(action: {
                    viewModel.query = ""
                    viewModel.drawerState = .idle
                    searchFocused = true
                    withAnimation { drawerDetent = .medium }
                }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        switch viewModel.drawerState {
        case .idle:
            suggestionsView

        case .loading:
            VStack(spacing: 12) {
                Spacer()
                ProgressView().tint(.wanderlyTerracotta)
                Text("Thinking...").font(.subheadline).foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)

        case .displaying(let response):
            ScrollView {
                VStack(spacing: 16) {
                    switch response.componentType {
                    case .placeList:
                        PlaceListComponent(
                            title: response.title ?? "Places",
                            places: viewModel.resolvePlaces(from: response.placeIds),
                            aiMessage: response.aiMessage
                        )

                    case .navigationCard:
                        if let place = viewModel.resolvePlace(id: response.navigationPlaceId) {
                            NavigationCardComponent(place: place, mode: response.transportMode)
                        } else {
                            messageView("Couldn't find that place in your collection.")
                        }

                    case .tripItinerary:
                        TripItineraryComponent(
                            title: response.title ?? "Your Itinerary",
                            days: response.itineraryDays,
                            aiMessage: response.aiMessage,
                            places: viewModel.places
                        )

                    case .message:
                        messageView(response.messageText ?? response.aiMessage ?? "")
                    }

                    // Follow-up: keeps conversation context
                    Button(action: {
                        viewModel.query = ""
                        searchFocused = true
                        withAnimation { drawerDetent = .medium }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "text.bubble")
                            Text("Follow up")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.wanderlyTerracotta)
                        .padding(.vertical, 6)
                    }

                    // New conversation: clears context
                    Button(action: {
                        viewModel.startNewConversation()
                        searchFocused = true
                        withAnimation { drawerDetent = .medium }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.bubble")
                            Text("New question")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    }
                }
            }

        case .placeDetail(let place):
            PlaceBottomSheet(place: place) {
                try await onDeletePlace(place)
                viewModel.removePlace(place)
                withAnimation(.spring(duration: 0.3)) {
                    drawerDetent = .height(72)
                }
            }

        case .error(let msg):
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: "exclamationmark.triangle").foregroundColor(.wanderlyTerracotta)
                Text(msg)
                    .font(.caption).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
                Button("Try again") { Task { await viewModel.submit() } }
                    .font(.caption).fontWeight(.semibold).foregroundColor(.wanderlyTerracotta)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func messageView(_ text: String) -> some View {
        VStack(spacing: 8) {
            Spacer()
            Text(text)
                .font(.subheadline)
                .foregroundColor(.wanderlyCharcoal)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var isLoading: Bool {
        if case .loading = viewModel.drawerState { return true }
        return false
    }

    private var showsContentArea: Bool {
        if case .idle = viewModel.drawerState, drawerDetent == .height(72) { return false }
        return true
    }

    // MARK: - Idle suggestions

    private var suggestionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Button(action: { viewModel.showPlaceList = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet")
                            Text("My Places")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.wanderlyTerracotta)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.wanderlyTerracotta.opacity(0.1))
                        .cornerRadius(16)
                    }

                    Button(action: { showGoogleTakeoutImport = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "tray.and.arrow.down")
                            Text("Import")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.wanderlyTerracotta)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.wanderlyTerracotta.opacity(0.1))
                        .cornerRadius(16)
                    }

                    Text("\(viewModel.places.count) saved")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                addSpotsHub

                if !viewModel.chatHistory.isEmpty {
                    Text("Recent")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    ForEach(viewModel.chatHistory.prefix(5)) { entry in
                        Button(action: {
                            viewModel.query = entry.query
                            Task { await viewModel.submit() }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(entry.query)
                                    .font(.subheadline)
                                    .foregroundColor(.wanderlyCharcoal)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }

                Text("Try asking")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        viewModel.query = suggestion
                        Task { await viewModel.submit() }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.left")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundColor(.wanderlyCharcoal)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }

    private let suggestions = [
        "Show my food spots on the map",
        "Navigate to the nearest cafe",
        "Plan a 2-day itinerary",
        "What haven't I visited yet?",
    ]

    // MARK: - Add Spots

    private var addSpotsHub: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SAV-E commands")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.wanderlyCharcoal)
                    Text("Give the agent a link, media, or notes. SAV-E investigates first, then asks before saving.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text("\(viewModel.places.count)")
                    .font(.caption.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(.wanderlyTerracotta)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.wanderlyTerracotta.opacity(0.1))
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: addSpotColumns, spacing: 10) {
                AgentCommandCard(
                    icon: "camera.viewfinder",
                    title: "Investigate link",
                    subtitle: "IG, TikTok, XHS, article, or map URL",
                    commandLabel: "returns candidates",
                    tone: .terracotta
                ) {
                    focusSocialInvestigationPrompt()
                }

                AgentCommandCard(
                    icon: "link",
                    title: "Import clipboard",
                    subtitle: "Read one copied URL into the agent",
                    commandLabel: "checks metadata",
                    tone: .sage
                ) {
                    importClipboardURL()
                }

                AgentCommandCard(
                    icon: "note.text",
                    title: "Parse notes",
                    subtitle: "Turn pasted lists into review candidates",
                    commandLabel: "no auto-save",
                    tone: .amber
                ) {
                    focusAgentPrompt("""
                    Turn these notes into reviewable place candidates.

                    Extract likely place names, city/address clues, category, evidence, confidence, and what is missing. Do not save anything automatically.

                    Notes:
                    """)
                }

                AgentCommandCard(
                    icon: "doc.viewfinder",
                    title: "Media Evidence",
                    subtitle: "Use screenshots or files as evidence",
                    commandLabel: "investigates",
                    tone: .blue
                ) {
                    focusMediaEvidencePrompt()
                }

                AgentCommandCard(
                    icon: "magnifyingglass",
                    title: "Find venue",
                    subtitle: "Resolve a fuzzy place into a real spot",
                    commandLabel: "verifies address",
                    tone: .charcoal
                ) {
                    focusAgentPrompt("""
                    Find the real venue for this place idea and return review candidates with evidence.

                    Include official name, address, city, source links, confidence, and whether it is safe to save. Do not save automatically.

                    Place idea:
                    """)
                }

                AgentCommandCard(
                    icon: "sparkles.rectangle.stack",
                    title: "Plan saved spots",
                    subtitle: "Build a route from confirmed places",
                    commandLabel: "uses saved places",
                    tone: .terracotta
                ) {
                    focusAgentPrompt("""
                    Help me organize my saved places into a practical plan.

                    Use only confirmed saved places unless I explicitly ask you to investigate new candidates. Start with:
                    """)
                }
            }

            ReviewCandidatesSection(
                candidates: reviewCandidates,
                actionInFlight: candidateActionInFlight,
                onConfirm: { candidate in
                    performCandidateAction(candidate, successMessage: "Candidate confirmed. Save it once the coordinates are reliable.") {
                        try await onConfirmCandidate(candidate)
                    }
                },
                onReject: { candidate in
                    performCandidateAction(candidate, successMessage: "Candidate rejected.") {
                        try await onRejectCandidate(candidate)
                    }
                },
                onSave: { candidate in
                    performCandidateAction(candidate, successMessage: "Saved as a place.") {
                        try await onSaveCandidate(candidate)
                    }
                }
            )

            if let addSpotStatus {
                Text(addSpotStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private var addSpotColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
        ]
    }

    private func focusSocialInvestigationPrompt() {
        if let clipboardText = UIPasteboard.general.string,
           let url = firstURL(in: clipboardText) {
            addSpotStatus = "Social link loaded. SAV-E will return candidates for review, not save automatically."
            focusAgentPrompt(socialInvestigationPrompt(for: url.absoluteString))
        } else {
            addSpotStatus = "Paste a public social/video link after the prompt, or share it into SAV-E."
            focusAgentPrompt(socialInvestigationPrompt(for: ""))
        }
    }

    private func socialInvestigationPrompt(for url: String) -> String {
        """
        Investigate this public social/video link and return candidate places with evidence.

        Use public preview metadata, pasted caption text, and reliable cross-checks only. If there is no explicit venue/address, return review candidates with confidence and missing evidence instead of saving.

        Link: \(url)
        """
    }

    private func focusMediaEvidencePrompt() {
        addSpotStatus = "Media evidence results stay as review candidates until you choose a place."
        focusAgentPrompt("""
        Investigate this video or screenshot and return candidate places with evidence.

        Use only evidence from the shared media, pasted caption/link, and reliable cross-checks.
        Return likely place candidates, evidence for each candidate, confidence, what is missing, and whether it is safe to save.

        Do not save anything automatically.
        """)
    }

    private func importClipboardURL() {
        guard let clipboardText = UIPasteboard.general.string,
              let url = firstURL(in: clipboardText) else {
            addSpotStatus = "Clipboard does not contain a URL yet. Copy a place or social link, then tap Import clipboard again."
            return
        }

        addSpotStatus = "Clipboard link loaded. SAV-E will ask before saving."
        focusAgentPrompt("""
        Import this public place link only if it has reliable metadata.

        Return the candidate place, evidence, confidence, missing fields, and whether it is safe to save. Do not save automatically.

        Link: \(url.absoluteString)
        """)
    }

    private func performCandidateAction(
        _ candidate: PlaceReviewCandidate,
        successMessage: String,
        action: @escaping () async throws -> Void
    ) {
        candidateActionInFlight = candidate.id
        Task {
            do {
                try await action()
                addSpotStatus = successMessage
            } catch {
                addSpotStatus = error.localizedDescription
            }
            candidateActionInFlight = nil
        }
    }

    private func focusAgentPrompt(_ prompt: String) {
        viewModel.startNewConversation()
        viewModel.query = prompt
        withAnimation { drawerDetent = .medium }
        searchFocused = true
    }

    private func firstURL(in text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector?
            .matches(in: text, options: [], range: range)
            .compactMap(\.url)
            .first { url in
                guard let scheme = url.scheme?.lowercased() else { return false }
                return scheme == "http" || scheme == "https"
            }
    }
}

private struct ReviewCandidatesSection: View {
    var candidates: [PlaceReviewCandidate]
    var actionInFlight: UUID?
    var onConfirm: (PlaceReviewCandidate) -> Void
    var onReject: (PlaceReviewCandidate) -> Void
    var onSave: (PlaceReviewCandidate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Review candidates", systemImage: "checklist.unchecked")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.wanderlyCharcoal)

                Spacer()

                Text("\(candidates.count)")
                    .font(.caption.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(.wanderlyTerracotta)
            }

            if candidates.isEmpty {
                ReviewCandidatesEmptyState()
            } else {
                ForEach(candidates.prefix(4)) { candidate in
                    ReviewCandidateCard(
                        candidate: candidate,
                        isWorking: actionInFlight == candidate.id,
                        onConfirm: { onConfirm(candidate) },
                        onReject: { onReject(candidate) },
                        onSave: { onSave(candidate) }
                    )
                }
            }
        }
    }
}

private struct ReviewCandidatesEmptyState: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checklist.unchecked")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.wanderlyTerracotta)
                .frame(width: 34, height: 34)
                .background(Color.wanderlyTerracotta.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("No pending candidates")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.wanderlyCharcoal)

                Text("Shared links, media evidence, and unresolved imports will land here for confirmation before they become saved places.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.wanderlyCharcoal.opacity(0.07), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
        )
    }
}

private struct ReviewCandidateCard: View {
    var candidate: PlaceReviewCandidate
    var isWorking: Bool
    var onConfirm: () -> Void
    var onReject: () -> Void
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: candidate.hasReliableCoordinates ? "mappin.and.ellipse" : "location.slash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(candidate.hasReliableCoordinates ? .wanderlySage : .wanderlyAmber)
                    .frame(width: 34, height: 34)
                    .background((candidate.hasReliableCoordinates ? Color.wanderlySage : Color.wanderlyAmber).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.wanderlyCharcoal)
                        .lineLimit(2)

                    Text(candidate.address.isEmpty ? "Needs address or map link" : candidate.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    if let confidence = candidate.confidence {
                        Text("Confidence \(Int(confidence * 100))% · \(candidate.status)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }

            if let evidence = candidate.evidence.first {
                Text(evidence)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if !candidate.hasReliableCoordinates {
                Text("Saving requires Google Places refinement or a map link.")
                    .font(.caption2)
                    .foregroundColor(.wanderlyTerracotta)
            }

            HStack(spacing: 8) {
                CandidateActionButton(title: "Confirm", systemImage: "checkmark", disabled: isWorking, action: onConfirm)
                CandidateActionButton(title: candidate.hasReliableCoordinates ? "Save" : "Refine + Save", systemImage: "tray.and.arrow.down", disabled: isWorking, action: onSave)
                CandidateActionButton(title: "Reject", systemImage: "xmark", disabled: isWorking, action: onReject)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.68))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.wanderlyCharcoal.opacity(0.08), lineWidth: 1)
                )
        )
        .opacity(isWorking ? 0.65 : 1)
    }
}

private struct CandidateActionButton: View {
    var title: String
    var systemImage: String
    var disabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.wanderlyTerracotta)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color.wanderlyTerracotta.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

private struct AgentCommandCard: View {
    enum Tone {
        case terracotta, sage, amber, blue, charcoal

        var color: Color {
            switch self {
            case .terracotta: return .wanderlyTerracotta
            case .sage: return .wanderlySage
            case .amber: return .wanderlyAmber
            case .blue: return Color(hex: "5B8FA8")
            case .charcoal: return .wanderlyCharcoal
            }
        }
    }

    let icon: String
    let title: String
    let subtitle: String
    let commandLabel: String
    let tone: Tone
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(tone.color)
                        .frame(width: 38, height: 38)
                        .background(tone.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(tone.color)
                        .padding(6)
                        .background(tone.color.opacity(0.08))
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.wanderlyCharcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(commandLabel.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(tone.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tone.color.opacity(0.08))
                    .clipShape(Capsule())

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(tone.color.opacity(0.12), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}
