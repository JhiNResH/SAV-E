import Foundation

@main
struct SocialLinkParserCheck {
    static func main() {
        let chineseCaption = """
        上海現在最難訂的一頓晚餐。
        不是米其林，
        卻比米其林更難搶。

        上海全新開幕敘宴新主題-敘敦煌
        不是餐廳，是一場沉浸式文化盛宴。

        從沙漠絲路到盛世敦煌，
        短短90分鐘，像看完一場文化大秀。
        門票、時段、位置交給我們就對了🧡
        """

        let chineseCandidates = SocialLinkReviewCandidateService.shared.reviewCandidates(
            fromEvidenceText: chineseCaption,
            sourceURL: "https://www.instagram.com/reel/DYejBrbpfXR/"
        )

        expect(chineseCandidates.count == 1, "Chinese caption should produce one review candidate")
        let chinese = chineseCandidates[0]
        expect(chinese.candidateName == "敘宴·敘敦煌", "Chinese venue name should be normalized")
        expect(chinese.address.isEmpty, "Chinese caption should not invent an address")
        expect(chinese.category == "food", "Chinese venue should infer food category")
        expect(chinese.confidence == 0.56, "Chinese venue without address should use review confidence")
        expect(chinese.missingInfo.contains("Confirm exact address"), "Chinese venue should require exact address confirmation")
        expect(chinese.missingInfo.contains("Confirm coordinates"), "Chinese venue should require coordinate confirmation")
        expect(chinese.missingInfo.contains("Cross-check official source or map listing"), "Chinese venue should require source cross-check")
        expect(chinese.missingInfo.contains("No structured location metadata"), "Chinese venue should record missing structured metadata")
        expect(chinese.candidateName != "不是餐廳，是一場沉浸式文化盛宴。", "Marketing line must not become venue name")
        expect(chinese.address != "從沙漠絲路到盛世敦煌，", "Marketing line must not become address")

        let numberedCaption = """
        1. Ulaman Eco Luxury Resort
        staying at @ulamanbali
        Bali, Indonesia

        2. Fabel Friet
        fresh parmesan and truffle mayo
        Amsterdam
        """

        let numberedCandidates = SocialLinkReviewCandidateService.shared.reviewCandidates(
            fromEvidenceText: numberedCaption,
            sourceURL: "https://www.instagram.com/reel/example/"
        )

        expect(numberedCandidates.count == 2, "Numbered social captions should still parse multiple candidates")
        expect(numberedCandidates[0].candidateName == "Ulaman Eco Luxury Resort", "First numbered candidate should be preserved")
        expect(numberedCandidates[1].candidateName == "Fabel Friet", "Second numbered candidate should be preserved")

        let teaHotPotCaption = """
        The FIRST AND ONLY US Tea themed hot pot is here!
        @fourseasonsteahousehotpot is located in Mountain View
        They have unique tea broths that are light, savory, and perfect for hot pot.
        """

        let teaHotPotCandidates = SocialLinkReviewCandidateService.shared.reviewCandidates(
            fromEvidenceText: teaHotPotCaption,
            sourceURL: "https://www.instagram.com/reel/DXfgsHvj3tW/"
        )

        expect(teaHotPotCandidates.count == 1, "Tea hot pot caption should produce one review candidate")
        expect(teaHotPotCandidates[0].candidateName == "Four Seasons Tea House Hot Pot", "Social handle should resolve to the public profile/listing name")
        expect(teaHotPotCandidates[0].candidateName != "are light", "Embedded 'that are light' must not be parsed as an at-place match")
        expect(teaHotPotCandidates[0].address == "Mountain View", "Mountain View should be preserved as the location clue")
        expect(teaHotPotCandidates[0].category == "food", "Tea hot pot candidate should infer food category")

        print("Validated social link parser fixtures.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            fputs("FAIL: \(message)\n", stderr)
            exit(1)
        }
    }
}
