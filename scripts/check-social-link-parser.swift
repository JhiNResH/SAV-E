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

        let ushigoroCaption = """
        #GIRLSTALK美食
        來自東京的頂級燒肉名店「USHIGORO S.」 @ushigoro.s.tw 正式插旗台北‼️💥

        主打少見的「和牛燒肉割烹」形式，將A5黑毛和牛結合日式割烹料理，從前菜、刺身、燒肉到主食一路精緻上桌。

        肉控必吃的「究極厚切黑牛舌」選用厚切舌根部位，搭配唐辛子味噌與大蒜醬油香氣超濃郁。

        📍中山區樂群三路299號2樓
        📅 5/8正式開放inline訂位
        """

        let ushigoroCandidates = SocialLinkReviewCandidateService.shared.reviewCandidates(
            fromEvidenceText: ushigoroCaption,
            sourceURL: "https://www.instagram.com/reel/DYG2S_4n3_e/"
        )

        expect(ushigoroCandidates.count == 1, "USHIGORO caption should produce one review candidate")
        let ushigoro = ushigoroCandidates[0]
        expect(ushigoro.candidateName == "USHIGORO S", "USHIGORO caption should extract the quoted venue name")
        expect(ushigoro.candidateName != "來自東京的頂級燒肉名店「USHIGORO S.」 @ushigoro.s.tw 正式插旗台北‼️💥", "Full caption sentence must not become venue name")
        expect(ushigoro.address == "中山區樂群三路299號2樓", "USHIGORO caption should preserve explicit location pin")
        expect(ushigoro.category == "food", "USHIGORO caption should infer food category")

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

        print("Validated social link parser fixtures.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            fputs("FAIL: \(message)\n", stderr)
            exit(1)
        }
    }
}
