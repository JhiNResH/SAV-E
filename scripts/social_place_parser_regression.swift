import Foundation

struct ParserRegressionCase {
    let name: String
    let sourceURL: String
    let evidence: String
    let expectedName: String
    let expectedAddress: String?
    let rejectedNameFragments: [String]
    let rejectedAddressFragments: [String]
}

let cases: [ParserRegressionCase] = [
    ParserRegressionCase(
        name: "Instagram launch headline extracts Standard Bread and pin location",
        sourceURL: "https://www.instagram.com/p/DY1nVh0n8mu/",
        evidence: """
        GIRLSTALK on Instagram: "#GIRLSTALK美食
        在韓國掀起排隊熱潮的法式吐司 Standard Bread 5/29即將在台北信義新天地A11正式開幕！

        主打「每30分鐘現烤出爐」的吐司，加上獨特的撕開沾醬吐司吃法，在韓國迅速爆紅。就連 BLACKPINK Jisoo、Super Junior 銀赫都曾到店朝聖！

        品牌必點招牌 「焦糖烤布蕾法式吐司」 外層炙燒成金黃焦糖脆殼，內層則柔軟濕潤，一口能同時吃到焦糖香與蛋奶香，另外更推薦「杜拜巧克力法式吐司」，吃得到開心果酥脆口感✨搭配歐洲鄉村風格的門市空間與剛出爐的奶油麵包香氣，讓信義區多一間新的排隊打卡美食！

        📍台北信義新天地 A11 B2
        📅 開幕日期：5/29正式開幕
        #StandardBread #韓國咖啡 #聖水洞美食 #Na編"
        """,
        expectedName: "Standard Bread",
        expectedAddress: "台北信義新天地 A11 B2",
        rejectedNameFragments: ["5/29", "在韓國掀起", "法式吐司 Standard Bread 5"],
        rejectedAddressFragments: ["品牌必點招牌", "焦糖烤布蕾", "現烤出爐"]
    )
]

@main
struct SocialPlaceParserRegressionRunner {
    static func main() {
        let parser = SocialPlaceParser()
        var failures: [String] = []

        for testCase in cases {
            let analysis = parser.analyze(
                evidence: SocialPlaceSourceEvidence(
                    sourceURL: testCase.sourceURL,
                    resolvedURL: nil,
                    sharedTitle: nil,
                    sharedText: testCase.evidence,
                    metadataTitle: nil,
                    metadataDescription: nil,
                    ocrLines: []
                )
            )

            guard let first = analysis.placesFound.first else {
                failures.append("\(testCase.name): no places found; intent=\(analysis.sourceIntent.rawValue), type=\(analysis.sourceType.rawValue)")
                continue
            }

            if first.displayName != testCase.expectedName {
                failures.append("\(testCase.name): expected name \(testCase.expectedName), got \(first.displayName)")
            }
            if let expectedAddress = testCase.expectedAddress, first.locationClues.first != expectedAddress {
                failures.append("\(testCase.name): expected address \(expectedAddress), got \(first.locationClues.first ?? "nil")")
            }
            for fragment in testCase.rejectedNameFragments where first.displayName.contains(fragment) {
                failures.append("\(testCase.name): rejected name fragment leaked: \(fragment)")
            }
            for fragment in testCase.rejectedAddressFragments where first.locationClues.joined(separator: " | ").contains(fragment) {
                failures.append("\(testCase.name): rejected address fragment leaked: \(fragment)")
            }
            if analysis.sourceType != .singleVenuePost || analysis.sourceIntent != .singleVenuePost {
                failures.append("\(testCase.name): expected single venue post; got type=\(analysis.sourceType.rawValue), intent=\(analysis.sourceIntent.rawValue)")
            }
        }

        if failures.isEmpty {
            print("social place parser regression: PASS (\(cases.count) cases)")
        } else {
            print("social place parser regression: FAIL")
            failures.forEach { print("- \($0)") }
            exit(1)
        }
    }
}
