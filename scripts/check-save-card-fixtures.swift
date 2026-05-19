import Foundation

@main
struct CheckSaveCardFixtures {
    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let fixtureDir = root.appendingPathComponent("fixtures/save-cards", isDirectory: true)
        let files = try FileManager.default.contentsOfDirectory(at: fixtureDir, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasSuffix(".card.json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        precondition(files.count >= 3, "expected at least three save.card.v0 fixtures")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        var sawInstagramReviewCandidate = false
        var sawLumaRedaction = false
        var sawGoogleMapsConfirmedPlace = false

        for file in files {
            let data = try Data(contentsOf: file)
            let card = try decoder.decode(SaveCard.self, from: data)
            precondition(card.isValidSchema, "\(file.lastPathComponent): invalid schema")
            precondition(card.id.hasPrefix("save_"), "\(file.lastPathComponent): invalid id")
            precondition(card.visibility == .private, "\(file.lastPathComponent): fixtures must start private")
            _ = try decoder.decode(SaveCard.self, from: encoder.encode(card))

            if card.source.kind == .instagram,
               card.places.contains(where: { $0.status == .reviewCandidate }) {
                sawInstagramReviewCandidate = true
            }
            if card.source.kind == .luma, !card.redactions.isEmpty {
                sawLumaRedaction = true
            }
            if card.source.kind == .googleMaps,
               card.places.contains(where: { $0.status == .confirmedPlace && $0.geo != nil }) {
                sawGoogleMapsConfirmedPlace = true
            }
        }

        precondition(sawInstagramReviewCandidate, "missing Instagram review_candidate fixture")
        precondition(sawLumaRedaction, "missing Luma redaction fixture")
        precondition(sawGoogleMapsConfirmedPlace, "missing Google Maps confirmed_place fixture")

        print("Validated \(files.count) save.card.v0 fixtures with Swift.")
    }
}
