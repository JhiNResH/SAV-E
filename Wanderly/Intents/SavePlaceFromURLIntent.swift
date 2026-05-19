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
        let record = try SaveLocalVaultService.shared.saveSourceOnly(
            url: url,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        return .result(dialog: "Saved \(record.displayTitle) to SAV-E memory for review.")
    }
}
