import Foundation

@main
struct SocialOSINTFixtureCheck {
    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let fixtureDir = root.appendingPathComponent("fixtures/social-osint", isDirectory: true)
        let service = SocialLinkReviewCandidateService()

        let mikantaichung = service.reviewCandidates(
            fromEvidenceText: try fixture("DX_cUWNmNxH_mikantaichung.txt", in: fixtureDir),
            sourceURL: "https://www.instagram.com/p/DX_cUWNmNxH/"
        )
        expect(mikantaichung.first?.candidateName == "蜜柑 關西風壽喜燒", "expected resolved profile name for mikantaichung")
        expect(mikantaichung.first?.missingInfo.contains("Evidence tier: weakCandidate") == true, "expected weak tier for handle-only candidate")

        let yakiniku = service.reviewCandidates(
            fromEvidenceText: try fixture("DYKRzPixTGd_4foodie_metrics.txt", in: fixtureDir),
            sourceURL: "https://www.instagram.com/reel/DYKRzPixTGd/"
        )
        expect(yakiniku.first?.candidateName == "YAKINIKU 37west NY", "expected leading venue before slash")
        expect(yakiniku.first?.candidateName != "再訪意願：🌕🌕🌕🌕🌗", "review metric must not become title")

        let addressOnly = service.reviewCandidates(
            fromEvidenceText: try fixture("operating_hours_address_only.txt", in: fixtureDir),
            sourceURL: "https://www.instagram.com/reel/address-only/"
        )
        expect(addressOnly.isEmpty, "address-only operating-hours fixture should not invent a venue title")

        let fourSeasons = service.reviewCandidates(
            fromEvidenceText: try fixture("four_seasons_that_are_light.txt", in: fixtureDir),
            sourceURL: "https://www.instagram.com/reel/DXfgsHvj3tW/"
        )
        expect(fourSeasons.first?.candidateName == "Four Seasons Tea House Hot Pot", "expected resolved Four Seasons profile name")
        expect(fourSeasons.first?.candidateName != "are light", "word-boundary collision must not produce are light")

        let ocrText = try fixture("DYZrjnzTGuD_tula_ocr.txt", in: fixtureDir)
        let ocrLines = ocrText.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let ocr = SocialOCRCandidateHeuristics.candidate(from: ocrLines)
        expect(ocr?.name == "TULA COFFEE", "expected OCR venue-like line")
        expect(ocr?.name != "台南爆漿巴斯克", "OCR product line must not become title")

        print("Validated social OSINT fixtures.")
    }

    private static func fixture(_ name: String, in directory: URL) throws -> String {
        try String(contentsOf: directory.appendingPathComponent(name), encoding: .utf8)
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() { fail(message) }
    }

    private static func fail(_ message: String) -> Never {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}
