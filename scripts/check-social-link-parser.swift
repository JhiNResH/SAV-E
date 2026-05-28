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

        let standardBreadCaption = """
        GIRLSTALK on Instagram: "#GIRLSTALK美食
        在韓國掀起排隊熱潮的法式吐司 Standard Bread 5/29即將在台北信義新天地A11正式開幕！

        主打「每30分鐘現烤出爐」的吐司，加上獨特的撕開沾醬吐司吃法，在韓國迅速爆紅。就連 BLACKPINK Jisoo、Super Junior 銀赫都曾到店朝聖！

        品牌必點招牌 「焦糖烤布蕾法式吐司」 外層炙燒成金黃焦糖脆殼，內層則柔軟濕潤，一口能同時吃到焦糖香與蛋奶香，另外更推薦「杜拜巧克力法式吐司」，吃得到開心果酥脆口感✨搭配歐洲鄉村風格的門市空間與剛出爐的奶油麵包香氣，讓信義區多一間新的排隊打卡美食！

        📍台北信義新天地 A11 B2
        📅 開幕日期：5/29正式開幕
        #StandardBread #韓國咖啡 #聖水洞美食 #Na編"
        """

        let standardBreadCandidates = SocialLinkReviewCandidateService.shared.reviewCandidates(
            fromEvidenceText: standardBreadCaption,
            sourceURL: "https://www.instagram.com/p/DY1nVh0n8mu/"
        )
        expect(standardBreadCandidates.count == 1, "Standard Bread IG post should produce one review candidate")
        expect(standardBreadCandidates[0].candidateName == "Standard Bread", "Launch headline should extract the brand, not the full marketing sentence/date")
        expect(standardBreadCandidates[0].address == "台北信義新天地 A11 B2", "Explicit pin line should win over marketing paragraphs as the location clue")
        expect(!standardBreadCandidates[0].candidateName.contains("5/29"), "Opening date must not leak into the venue name")
        expect(!standardBreadCandidates[0].address.contains("品牌必點招牌"), "Marketing paragraph must not become address")

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
