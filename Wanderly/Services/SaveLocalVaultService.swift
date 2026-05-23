import Foundation

enum SaveLocalVaultError: LocalizedError {
    case storageUnavailable

    var errorDescription: String? {
        switch self {
        case .storageUnavailable:
            return "SAV-E local memory storage is unavailable."
        }
    }
}

final class SaveLocalVaultService {
    static let shared = SaveLocalVaultService()

    private let fileManager: FileManager
    private let fileName = "save-memory-records.json"
    private let overrideVaultURL: URL?

    init(fileManager: FileManager = .default, overrideVaultURL: URL? = nil) {
        self.fileManager = fileManager
        self.overrideVaultURL = overrideVaultURL
    }

    func append(_ record: SaveMemoryRecord) throws {
        var records = try loadRecords()
        records.insert(record, at: 0)
        try save(records)
    }

    func recentRecords(limit: Int = 25) throws -> [SaveMemoryRecord] {
        Array(try loadRecords().prefix(limit))
    }

    func saveSourceOnly(url: URL, note: String? = nil) throws -> SaveMemoryRecord {
        let diagnostic = sourceOnlyDiagnostic(url: url, note: note)
        let record = SaveMemoryRecord(
            state: .sourceOnly,
            sourceURL: url.absoluteString,
            sourceText: note,
            title: sourceOnlyDisplayName(for: url),
            evidence: diagnostic.found + diagnostic.attempts,
            evidenceDiagnostic: diagnostic
        )
        try append(record)
        return record
    }

    func saveReviewCandidate(_ candidate: PendingReviewCandidate) throws -> SaveMemoryRecord {
        let record = SaveMemoryRecord(
            state: candidate.isSourceOnly ? .sourceOnly : .reviewCandidate,
            sourceURL: candidate.sourceURL,
            sourceText: candidate.sourceText,
            title: candidate.candidateName,
            placeName: candidate.isSourceOnly ? nil : candidate.candidateName,
            address: candidate.address.isEmpty ? nil : candidate.address,
            evidence: candidate.evidence,
            evidenceDiagnostic: candidate.evidenceDiagnostic,
            createdAt: candidate.savedAt
        )
        try append(record)
        return record
    }

    func saveReviewCandidate(_ candidate: PlaceReviewCandidate) throws -> SaveMemoryRecord {
        let record = SaveMemoryRecord(
            state: .reviewCandidate,
            title: candidate.name,
            placeName: candidate.name,
            address: candidate.address.isEmpty ? nil : candidate.address,
            evidence: candidate.evidence,
            createdAt: candidate.createdAt
        )
        try append(record)
        return record
    }

    func saveConfirmedPlace(_ place: Place) throws -> SaveMemoryRecord {
        let record = SaveMemoryRecord(
            state: .confirmedPlace,
            sourceURL: place.sourceUrl,
            sourceText: place.note,
            title: place.name,
            placeName: place.name,
            address: place.address,
            evidence: place.note.map { [$0] } ?? [],
            createdAt: place.createdAt
        )
        try append(record)
        return record
    }

    private func loadRecords() throws -> [SaveMemoryRecord] {
        guard let url = vaultURL() else { throw SaveLocalVaultError.storageUnavailable }
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder.saveVault.decode([SaveMemoryRecord].self, from: data)
    }

    private func save(_ records: [SaveMemoryRecord]) throws {
        guard let url = vaultURL() else { throw SaveLocalVaultError.storageUnavailable }
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder.saveVault.encode(records)
        try data.write(to: url, options: [.atomic])
    }

    private func vaultURL() -> URL? {
        if let overrideVaultURL { return overrideVaultURL }
        if let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: WanderlySharedStorage.appGroupSuiteName) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }

    private func sourceOnlyDisplayName(for url: URL) -> String {
        let path = url.path.lowercased()
        if path.contains("/reel/") || path.contains("/reels/") { return "Instagram reel" }
        if url.host()?.lowercased().contains("instagram") == true { return "Instagram link" }
        return url.host() ?? url.absoluteString
    }

    private func sourceOnlyDiagnostic(url: URL, note: String?) -> SocialPlaceEvidenceDiagnostic {
        var found = ["Source URL: \(url.absoluteString)"]
        if note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            found.append("Shared text/caption was present but did not contain a verified place candidate")
        }
        return SocialPlaceEvidenceDiagnostic(
            found: found,
            attempts: [
                "Saved the original source before place evidence was verified",
                "Kept this as a source-only clue instead of inventing a place"
            ],
            missingFields: [
                "Verified place name",
                "Verified address",
                "Verified coordinates"
            ],
            nextBestClue: "Share a caption, screenshot/OCR frame, map link, or visible venue handle for this Reel."
        )
    }
}

private extension JSONEncoder {
    static var saveVault: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var saveVault: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
