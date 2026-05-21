import Foundation

struct SocialOCRCandidateResult {
    var name: String
    var confidence: Double
    var supportingLines: [String] = []
}

enum SocialOCRCandidateHeuristics {
    static func candidate(from lines: [String]) -> SocialOCRCandidateResult? {
        let cleanedLines = lines
            .map(cleanLine)
            .filter(isUsableLine)

        if let pairedBrand = bestPairedBrand(in: cleanedLines) {
            return pairedBrand
        }

        if let cafeLine = cleanedLines.first(where: { line in
            line.range(of: #"(?i)\b(coffee|cafe|bakery|bistro|restaurant|bar|tea)\b"#, options: .regularExpression) != nil &&
            !SocialPlaceEvidenceScorer.isRejectedTitle(line)
        }) {
            return SocialOCRCandidateResult(name: cafeLine, confidence: 0.46, supportingLines: [cafeLine])
        }

        if let uppercaseBrand = cleanedLines.first(where: { line in
            line.range(of: #"^[A-Z][A-Z0-9 &'._-]{2,30}$"#, options: .regularExpression) != nil &&
            !SocialPlaceEvidenceScorer.isRejectedTitle(line)
        }) {
            return SocialOCRCandidateResult(name: uppercaseBrand, confidence: 0.42, supportingLines: [uppercaseBrand])
        }

        return nil
    }

    private static func bestPairedBrand(in lines: [String]) -> SocialOCRCandidateResult? {
        guard lines.count > 1 else { return nil }
        for index in lines.indices {
            let line = lines[index]
            guard line.range(of: #"^[A-Z][A-Z0-9 &'._-]{2,30}$"#, options: .regularExpression) != nil,
                  !SocialPlaceEvidenceScorer.isRejectedTitle(line) else { continue }
            let neighbors = [index - 1, index + 1]
                .filter { lines.indices.contains($0) }
                .map { lines[$0] }
            if neighbors.contains(where: looksLikeVenueDescriptor) {
                return SocialOCRCandidateResult(name: line, confidence: 0.5, supportingLines: [line] + neighbors)
            }
        }
        return nil
    }

    private static func looksLikeVenueDescriptor(_ value: String) -> Bool {
        value.range(of: #"(?i)\b(coffee|cafe|bakery|bistro|restaurant|bar|tea|brunch|basque|dessert)\b"#, options: .regularExpression) != nil
    }

    private static func cleanLine(_ value: String) -> String {
        value
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'“”.,:;! "))
    }

    private static func isUsableLine(_ value: String) -> Bool {
        value.count >= 2 && value.count <= 60
    }
}
