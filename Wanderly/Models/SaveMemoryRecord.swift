import Foundation

enum SaveMemoryState: String, Codable, CaseIterable {
    case sourceOnly = "source_only"
    case reviewCandidate = "review_candidate"
    case confirmedPlace = "confirmed_place"

    var displayName: String {
        switch self {
        case .sourceOnly: return "Source only"
        case .reviewCandidate: return "Review candidate"
        case .confirmedPlace: return "Confirmed place"
        }
    }
}

struct SaveMemoryRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var state: SaveMemoryState
    var sourceURL: String?
    var sourceText: String?
    var title: String
    var placeName: String?
    var address: String?
    var evidence: [String]
    var evidenceDiagnostic: SocialPlaceEvidenceDiagnostic?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        state: SaveMemoryState,
        sourceURL: String? = nil,
        sourceText: String? = nil,
        title: String,
        placeName: String? = nil,
        address: String? = nil,
        evidence: [String] = [],
        evidenceDiagnostic: SocialPlaceEvidenceDiagnostic? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.state = state
        self.sourceURL = sourceURL
        self.sourceText = sourceText
        self.title = title
        self.placeName = placeName
        self.address = address
        self.evidence = evidence
        self.evidenceDiagnostic = evidenceDiagnostic
        self.createdAt = createdAt
    }

    var displayTitle: String {
        if let placeName, !placeName.isEmpty { return placeName }
        if !title.isEmpty { return title }
        return sourceURL ?? "Untitled source"
    }
}
