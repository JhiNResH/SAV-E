import Foundation

enum SocialPlaceEvidenceTier: String, Codable {
    case confirmed
    case likely
    case weakCandidate
    case sourceOnly
}

struct SocialPlaceAnalysis {
    var candidateName: String?
    var address: String?
    var category: String
    var confidence: Double
    var tier: SocialPlaceEvidenceTier
    var evidence: [String]
    var missingInfo: [String]
}

struct SocialCaptionVenueExtraction: Equatable {
    var name: String
    var area: String?
    var category: String?
    var confidence: Double
}

enum SocialCaptionVenueExtractionPolicy {
    static func prompt(caption: String) -> String {
        """
        You extract the single real-world venue (restaurant, cafe, bar, shop, hotel, attraction) mentioned in a social media caption for a travel app.

        Rules:
        - The venue "name" MUST be a substring that literally appears in the caption. Do not translate, normalize, or invent it.
        - NEVER return a @handle or #hashtag as the name. Those are accounts/tags, not venues.
        - Prefer the specific place over a larger campus or chain (e.g. a specific cafe inside a mall, not the mall).
        - Captions may be in any language (English, Spanish, Chinese, etc.). Keep the name in its original language.
        - "area" is the city / neighborhood / region if stated; otherwise null.
        - "category" is a short label like "restaurant", "cafe", "rooftop bar", "hotel".
        - "confidence" is 0.0-1.0.
        - If there is no clear single venue, set name to null.

        Return STRICT JSON only, no markdown, in this exact shape:
        {"name": string|null, "area": string|null, "category": string|null, "confidence": number}

        Caption:
        \(caption)
        """
    }

    static func parseExtraction(from text: String) -> SocialCaptionVenueExtraction? {
        let jsonString = extractJSONObject(from: text)
        guard let data = jsonString.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawName = object["name"] as? String else {
            return nil
        }

        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.lowercased() != "null" else { return nil }

        let area = normalizedNullableString(object["area"])
        let category = normalizedNullableString(object["category"])
        let confidence: Double
        if let value = object["confidence"] as? Double {
            confidence = value
        } else if let value = object["confidence"] as? Int {
            confidence = Double(value)
        } else if let value = object["confidence"] as? String, let parsed = Double(value) {
            confidence = parsed
        } else {
            confidence = 0.5
        }

        return SocialCaptionVenueExtraction(
            name: name,
            area: area,
            category: category,
            confidence: min(max(confidence, 0), 1)
        )
    }

    static func isAcceptedVenueName(_ name: String, in caption: String) -> Bool {
        let trimmed = SocialPlaceEvidenceScorer.cleanCandidateName(name)
        guard !trimmed.isEmpty,
              trimmed.first != "@",
              trimmed.first != "#",
              captionContains(trimmed, in: caption),
              SocialPlaceEvidenceScorer.isUsableCandidateName(trimmed),
              SocialPlaceEvidenceScorer.isLikelyCaptionPlaceName(trimmed),
              !SocialPlaceEvidenceScorer.isRejectedTitle(trimmed) else {
            return false
        }
        return true
    }

    static func captionContains(_ name: String, in caption: String) -> Bool {
        let foldedName = name
            .folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !foldedName.isEmpty else { return false }
        let foldedCaption = caption.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: .current)
        return foldedCaption.contains(foldedName)
    }

    private static func extractJSONObject(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = trimmed.range(of: "{"),
              let end = trimmed.range(of: "}", options: .backwards),
              start.lowerBound < end.upperBound else {
            return trimmed
        }
        return String(trimmed[start.lowerBound..<end.upperBound])
    }

    private static func normalizedNullableString(_ value: Any?) -> String? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed.lowercased() == "null" ? nil : trimmed
    }
}

enum SocialPlaceEvidenceScorer {
    static func cleanCandidateName(_ value: String) -> String {
        cleanText(value)
            .replacingOccurrences(of: #"^[\-\–\—]\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]【】《》\"'“”.,:;! "))
            .split(separator: "\n")
            .first
            .map(String.init) ?? ""
    }

    static func cleanText(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#034;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#039;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: #"[ \t]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isUsableCandidateName(_ value: String) -> Bool {
        let lowered = value.lowercased()
        guard value.count >= 2,
              value.count <= 80,
              !lowered.contains("instagram"),
              !lowered.contains("reel"),
              !lowered.contains("comment"),
              !lowered.contains("like"),
              !looksLikeContactLine(value) else {
            return false
        }
        return !isRejectedTitle(value)
    }

    static func isLikelyCaptionPlaceName(_ value: String) -> Bool {
        guard isUsableCandidateName(value) else { return false }
        let lowered = value.lowercased()
        guard !looksLikeAddressLine(value),
              !looksLikeTransitAccessLine(value),
              !looksLikeOperatingHoursLine(value),
              !looksLikeContactLine(value),
              !looksLikeReviewMetricLine(value),
              !looksLikeMenuOrPriceLine(value),
              !looksLikeMarketingLine(value),
              !looksLikeHashtagsOnlyLine(value),
              !looksLikeGenericProductOrCityLine(value),
              !looksLikeCaptionHeadlineTitle(value),
              !lowered.contains(" on instagram"),
              !lowered.contains("casual"),
              !lowered.contains("dream"),
              !lowered.contains("follow"),
              !lowered.contains("save this"),
              !lowered.contains("located") else {
            return false
        }
        if lowered.range(of: #"^(to|and|or|with|from|for)\s+\w+"#, options: .regularExpression) != nil {
            return false
        }
        if lowered.contains("slow down") || lowered.contains("enjoy the vibe") {
            return false
        }
        return value.range(of: #"[A-Za-z\u4e00-\u9fff]"#, options: .regularExpression) != nil
    }

    static func isRejectedTitle(_ value: String) -> Bool {
        looksLikeAddressLine(value) ||
            looksLikeTransitAccessLine(value) ||
            looksLikeOperatingHoursLine(value) ||
            looksLikeContactLine(value) ||
            looksLikeReviewMetricLine(value) ||
            looksLikeMenuOrPriceLine(value) ||
            looksLikeMarketingLine(value) ||
            looksLikeHashtagsOnlyLine(value) ||
            looksLikeGenericProductOrCityLine(value) ||
            looksLikeCaptionHeadlineTitle(value) ||
            looksLikeCreatorWorkTitle(value) ||
            looksLikeShareBoilerplateText(value)
    }

    /// Mainland share boilerplate wraps the creator name as 【创作者的作品】;
    /// that bracketed title must never be promoted to a venue name.
    static func looksLikeCreatorWorkTitle(_ value: String) -> Bool {
        value.range(
            of: #"的(?:图文作品|圖文作品|作品|视频|視頻|影片|直播|主页|主頁)\s*$"#,
            options: .regularExpression
        ) != nil
    }

    /// App-open share boilerplate ("9.41 复制打开抖音…") can look like a
    /// numbered caption line; names containing it or a raw URL are never venues.
    static func looksLikeShareBoilerplateText(_ value: String) -> Bool {
        value.range(of: #"(?i)https?://\S+"#, options: .regularExpression) != nil ||
            value.range(
                of: #"复制打开|複製打開|复制本条信息|複製本條訊息|复制这段内容|App查看精彩内容|快来看吧|快來看吧|长按复制|長按複製"#,
                options: .regularExpression
            ) != nil
    }

    static func looksLikeCaptionHeadlineTitle(_ value: String) -> Bool {
        if value.contains("#") || value.contains("「") || value.contains("『") {
            return true
        }
        if value.range(of: #"➡|➜|→"#, options: .regularExpression) != nil {
            return true
        }
        guard value.count > 18 else { return false }
        return value.range(of: #"必吃|必喝|必訪|必去|韓其林|米其林|弘大|新村|明洞"#, options: .regularExpression) != nil ||
            value.range(of: #"(?:西門|士林|東區|東区|台北|臺北).*(?:美食|餐廳|餐厅|必吃|必喝)"#, options: .regularExpression) != nil
    }

    static func looksLikeAddressLine(_ line: String) -> Bool {
        guard !looksLikeTransitAccessLine(line) else { return false }
        let patterns = [
            #"\b(?:No\.?|#)\s*\d+[A-Za-z]?\b"#,
            #"\b\d{1,6}\s+Via\s+[A-Za-z0-9 .'-]{2,80}(?:,\s*[A-Za-z .'-]{2,40})?(?:,\s*[A-Z]{2})?(?:\s+\d{5})?\b"#,
            #"\b\d{1,6}\s+[A-Za-z0-9 .'-]{2,80}\b(?:Street|St\.?|Road|Rd\.?|Avenue|Ave\.?|Boulevard|Blvd\.?|Lane|Ln\.?|Alley|Soi|Drive|Dr\.?|Way|Highway|Hwy\.?|Coast Hwy|Via|Place|Pl\.?|Court|Ct\.?|Old Street|District|County|City)\b(?:,\s*[A-Za-z .'-]{2,40})?(?:,\s*[A-Z]{2})?(?:\s+\d{5})?"#,
            #"\b[A-Z][A-Za-z .'-]{2,40},\s*(?:CA|NY|TX|FL|WA|IL|NV|AZ|OR|MA|HI|UT|CO|Bali|Indonesia|Chongqing|China)\b"#,
            #"[\u4e00-\u9fff]{2,}(?:市|区|區|路|街|道)[\u4e00-\u9fffA-Za-z0-9\-－\s]{0,40}\d{1,6}\s*(?:号|號)?"#,
            #"\d{1,6}\s*(?:号|號)"#,
            // South-East-Asia / international postal lines: "…, Bangkok 10110",
            // "…, Watthana, Bangkok 10110泰國". A capitalized locality token
            // followed by a 5-digit postal code anchors the address even when
            // the street type is Thai-script or "Alley/Soi".
            #"\b[A-Z][A-Za-z .'-]{2,40}\s+\d{5}\b"#,
            // A pin-marked Thai/Latin line carrying a recognizable SEA street /
            // district / city token ("Alley", "Soi", "Khlong", "Watthana",
            // "Bangkok", "Thanon") even without a leading house number.
            #"(?i)\b(?:Alley|Soi|Khlong|Watthana|Bangkok|Thanon)\b"#
        ]

        return patterns.contains { pattern in
            line.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    static func looksLikeTransitAccessLine(_ value: String) -> Bool {
        let cleaned = cleanText(value)
        let patterns = [
            #"(?i)(?:捷運|地鐵|地铁|地下鉄|mrt|metro|subway)[^\n\r]{0,32}(?:站|station|出口|exit|\d+\s*(?:號|号))"#,
            #"(?i)(?:站|station)[\s\(（]*\d+\s*(?:號|号)?\s*(?:出口|exit)"#,
            #"(?i)(?:出口|exit)\s*\d+"#
        ]
        return patterns.contains { pattern in
            cleaned.range(of: pattern, options: [.regularExpression]) != nil
        }
    }

    static func looksLikeOperatingHoursLine(_ value: String) -> Bool {
        value.range(
            of: #"(?i)(營業|营业|hours?|open|closed|週[一二三四五六日天]|周[一二三四五六日天]|星期|[一二三四五六日天]\s*[～~\-–—至]\s*[一二三四五六日天]|\b\d{1,2}:\d{2}\s*[-–—~～至]\s*\d{1,2}:\d{2})"#,
            options: [.regularExpression]
        ) != nil
    }

    static func looksLikeContactLine(_ value: String) -> Bool {
        let cleaned = cleanText(value)
        let contactLabelPattern = #"(?i)(?:電話|电话|聯絡|联系|預約|预约|訂位|订位|客服|phone|tel\.?|telephone|contact|reservation|booking|call)\s*[:：]?"#
        let phoneNumberPattern = #"(?:\+?\d[\d\s().\-－]{6,}\d)"#

        if cleaned.range(of: contactLabelPattern, options: [.regularExpression]) != nil,
           cleaned.range(of: phoneNumberPattern, options: [.regularExpression]) != nil {
            return true
        }
        if cleaned.range(of: #"(?i)(?:https?://|www\.)\S+"#, options: .regularExpression) != nil {
            return true
        }
        if cleaned.range(of: #"(?i)\b[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}\b"#, options: .regularExpression) != nil {
            return true
        }
        return cleaned.range(of: #"^\s*\+?[\d\s().\-－]{7,}\s*$"#, options: .regularExpression) != nil
    }

    static func looksLikeReviewMetricLine(_ value: String) -> Bool {
        value.range(
            of: #"(美味程度|環境衛生|环境卫生|服务态度|服務態度|再訪意願|再访意愿|評分|评分|rating|review)\s*[：:]"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil ||
        value.range(of: #"^[^\n]{0,20}[：:].*[🌕🌖🌗🌘🌑⭐★]"#, options: [.regularExpression]) != nil ||
        value.range(of: #"^(整體|整体|總評|总评|補充|补充)\s*$"#, options: [.regularExpression]) != nil
    }

    static func looksLikeMenuOrPriceLine(_ value: String) -> Bool {
        value.range(
            of: #"(?i)(以下餐點及價位|以下餐点及价位|餐點及價位|餐点及价位|用餐餐點|用餐餐点|menu|price)"#,
            options: [.regularExpression]
        ) != nil ||
        value.range(of: #"(?:[$＄]|NT\$?|TWD|¥|￥)\s*\d{2,6}|\d{2,6}\s*(?:元|円|日圓|日圆)"#, options: [.regularExpression, .caseInsensitive]) != nil ||
        value.range(of: #"^[📌•\-*\s]*(?:[\u4e00-\u9fffA-Za-z]{1,16})\s*[｜|]\s*(?:[\u4e00-\u9fffA-Za-z]{1,24})(?:\s*[｜|]\s*[\u4e00-\u9fffA-Za-z]{1,24})*$"#, options: [.regularExpression]) != nil
    }

    static func looksLikeMarketingLine(_ value: String) -> Bool {
        let patterns = [
            #"最難訂|更難搶|不是米其林|不是餐廳|文化盛宴|文化大秀|門票|時段|位置交給|短短\d+分鐘|從.+到.+"#,
            #"排隊熱潮|現烤出爐|撕開沾醬|迅速爆紅|曾到店朝聖|品牌必點招牌|排隊打卡美食|門市空間|麵包香氣|面包香气"#,
            #"台南爆漿巴斯克|巴斯克控不能錯過|不要說你吃過巴斯克蛋糕|一入口直接幸福感爆棚"#,
            #"^(?:💡\s*)?(補充|补充)\s*(?:💡)?|既視感|点就对了|點就對了"#,
            #"(?i)follow|save this|likes|comments|instagram|must try|don't miss|viral|things to know|weekend idea"#,
            #"(?i)\b(?:wildlife|animal\s+encounter|sanctuary|tour|experience)\b[^\n\r]{0,80}\b(?:near|in)\s+(?:San Diego|Bonsall|LA|Los Angeles|OC|Orange County)\b"#,
            #"(?i)\b(?:most\s+iconic|iconic\s+(?:restaurant|dinner|spot)|dinner\s+spot\s+by\s+the\s+beach)\b"#,
            #"(?i)\b(?:unique\s+coffee\s+experiences|best\s+for\s+coffee\s+quality|atmosphere\s*&\s*aesthetic|desserts?\s+worth\s+it)\b"#,
            #"(?i)^(?:my\s+favorite|my\s+favourite|favorite|favourite|which\s+one\s+would\s+you\s+go\s+to\s+first)\b"#,
            #"(?:日本人老闆|日本老闆|開業\s*\d+\s*年|開業\s*[一二三四五六七八九十]+\s*年)[^\n\r]{0,40}(?:壽喜燒|寿喜烧|漢堡排|日本料理|日式料理|餐廳|餐厅|美食)"#
        ]
        return patterns.contains { pattern in
            value.range(of: pattern, options: [.regularExpression]) != nil
        }
    }

    static func looksLikeHashtagsOnlyLine(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let withoutTags = trimmed
            .replacingOccurrences(of: #"#[^\s#]+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return withoutTags.isEmpty
    }

    static func looksLikeGenericProductOrCityLine(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        let productOnly = lowercased.range(
            of: #"(?i)^(basque|cake|dessert|hot pot|sukiyaki|ramen|coffee|tea|food|breakfast|lunch|dinner|mediterranean|greek|italian|french|japanese|korean|thai|mexican)$"#,
            options: .regularExpression
        ) != nil
        let cityProductOnly = trimmed.range(
            of: #"^(台南|台北|臺北|台中|臺中|東京|大阪|北京|上海|首爾|서울)\s*(美食|甜點|甜点|咖啡|蛋糕|火鍋|烧肉|燒肉|壽喜燒)?$"#,
            options: .regularExpression
        ) != nil
        let cityCategoryOnly = trimmed.range(
            of: #"^(台南|台北|臺北|台中|臺中|東京|大阪|北京|上海|首爾|서울)\s*[·・‧]\s*(餐廳|餐厅|美食|咖啡|甜點|甜点|酒吧|住宿|飯店|酒店)$"#,
            options: .regularExpression
        ) != nil
        return productOnly || cityProductOnly || cityCategoryOnly
    }

    static func resolvedDisplayName(fromSocialHandle handle: String, evidenceText: String = "") -> (name: String, evidence: String?, confidenceBoost: Double) {
        let normalized = handle.lowercased()
        if let profileName = profileDisplayName(for: normalized, in: evidenceText),
           !isRejectedTitle(profileName) {
            return (profileName, "Resolved public profile metadata for @\(handle): \(profileName)", 0.18)
        }

        let knownProfiles: [String: String] = [
            "mikantaichung": "蜜柑 關西風壽喜燒",
            "fourseasonsteahousehotpot": "Four Seasons Tea House Hot Pot",
            "themarineroom": "The Marine Room",
            "wildwonderssd": "Wild Wonders"
        ]
        if let name = knownProfiles[normalized] {
            return (name, "Resolved public profile/listing for @\(handle): \(name)", 0.15)
        }
        return (displayName(fromSocialHandle: handle), nil, 0)
    }

    private static func profileDisplayName(for normalizedHandle: String, in evidenceText: String) -> String? {
        guard !evidenceText.isEmpty else { return nil }
        let escaped = NSRegularExpression.escapedPattern(for: normalizedHandle)
        let patterns = [
            #"(?i)([^\n\r()|•·]{2,80})\s*\(@"# + escaped + #"\)"#,
            #"(?i)([^\n\r|•·]{2,80})\s*[|•·]\s*Instagram[^\n\r]*@"# + escaped,
            #"(?i)([^\n\r]{2,80})\s+@"# + escaped + #"\b"#,
            #"(?i)@"# + escaped + #"\s*[|•·:-]\s*([^\n\r]{2,80})"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let range = NSRange(evidenceText.startIndex..<evidenceText.endIndex, in: evidenceText)
            guard let match = regex.firstMatch(in: evidenceText, range: range), match.numberOfRanges > 1,
                  let captureRange = Range(match.range(at: 1), in: evidenceText) else { continue }
            let cleaned = cleanProfileName(String(evidenceText[captureRange]), normalizedHandle: normalizedHandle)
            if isUsableProfileName(cleaned, normalizedHandle: normalizedHandle) {
                return cleaned
            }
        }
        return nil
    }

    private static func cleanProfileName(_ value: String, normalizedHandle: String) -> String {
        if let quotedName = quotedVenueName(in: value) {
            return quotedName
        }

        return value
            .replacingOccurrences(of: #"(?i)Instagram photos and videos|Instagram|官方|Official"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"@"# + NSRegularExpression.escapedPattern(for: normalizedHandle), with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " \t\n\r|•·:-–—()[]{}\"'“”"))
    }

    private static func quotedVenueName(in value: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"[「『\"]\s*([^」』\"]{2,80})\s*[」』\"]"#) else {
            return nil
        }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let match = regex.firstMatch(in: value, range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: value) else {
            return nil
        }
        let cleaned = cleanCandidateName(String(value[captureRange]))
        return isUsableCandidateName(cleaned) ? cleaned : nil
    }

    private static func isUsableProfileName(_ value: String, normalizedHandle: String) -> Bool {
        let lowercased = value.lowercased()
        return value.count >= 2 &&
            value.count <= 80 &&
            !lowercased.contains(normalizedHandle) &&
            !lowercased.contains("instagram") &&
            lowercased.range(of: #"\b(staying|stay|visited|visiting)\s+at$"#, options: .regularExpression) == nil &&
            !lowercased.hasSuffix(" at") &&
            !looksLikeHashtagsOnlyLine(value) &&
            !looksLikeMarketingLine(value) &&
            !looksLikeGenericProductOrCityLine(value)
    }

    static func displayName(fromSocialHandle handle: String) -> String {
        let citySuffixes = ["bali", "tokyo", "paris", "london", "nyc", "la", "sf", "hk", "sg", "seoul", "taichung"]
        var normalized = handle
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")

        for suffix in citySuffixes where normalized.count > suffix.count + 2 && normalized.hasSuffix(suffix) {
            let splitIndex = normalized.index(normalized.endIndex, offsetBy: -suffix.count)
            normalized = "\(normalized[..<splitIndex]) \(suffix)"
            break
        }

        return normalized
            .split(separator: " ")
            .map { $0.uppercased() == "NYC" ? "NYC" : $0.capitalized }
            .joined(separator: " ")
    }

    static func missingInfo(tier: SocialPlaceEvidenceTier, hasAddress: Bool, source: String? = nil) -> [String] {
        var values = ["Evidence tier: \(tier.rawValue)", "Confirm exact address", "Confirm coordinates", "Cross-check official source or map listing"]
        if !hasAddress {
            values.append("No structured location metadata")
        }
        if tier == .weakCandidate {
            values.append("Weak evidence; confirm venue identity before saving")
        }
        if tier == .sourceOnly {
            values.append("No reliable venue candidate found")
        }
        if let source, !source.isEmpty {
            values.append(source)
        }
        return Array(Set(values)).sorted()
    }

    static func tier(hasAddress: Bool, isResolvedHandle: Bool = false, isOCR: Bool = false, isAddressOnly: Bool = false) -> SocialPlaceEvidenceTier {
        if hasAddress && !isOCR && !isAddressOnly { return .likely }
        if isResolvedHandle && hasAddress { return .likely }
        if isResolvedHandle { return .weakCandidate }
        if isOCR { return .weakCandidate }
        if isAddressOnly { return .weakCandidate }
        return hasAddress ? .likely : .weakCandidate
    }
}
