import AppIntents
import Foundation

struct SavePlaceFromURLIntent: AppIntent {
    static var title: LocalizedStringResource = "Save URL to SAV-E"
    static var description = IntentDescription("Save a place, event, or social URL into SAV-E local memory for later review.")
    static var openAppWhenRun = false

    @Parameter(title: "URL")
    var url: URL

    @Parameter(title: "Note", default: "")
    var note: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            let candidates = try await SocialLinkReviewCandidateService.shared.reviewCandidates(from: url)
            for candidate in candidates {
                _ = try SaveLocalVaultService.shared.saveReviewCandidate(candidate)
            }
            let countLabel = candidates.count == 1 ? "1 review candidate" : "\(candidates.count) review candidates"
            return .result(dialog: "Saved \(countLabel) to SAV-E Review.")
        } catch {
            let record = try SaveLocalVaultService.shared.saveSourceOnly(
                url: url,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            return .result(dialog: "Saved \(record.displayTitle) to SAV-E memory as source-only. Open SAV-E to review it.")
        }
    }
}
