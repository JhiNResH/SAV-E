import Foundation

struct TripGapSuggestionEngine {
    func suggestions(
        for gaps: [TripGap],
        days: [ItineraryDay],
        savedPlaces: [Place],
        reviewCandidates: [PlaceReviewCandidate],
        mapCandidates: [SaveMapCandidate],
        outputLanguage: AppLanguage
    ) -> [GapSuggestion] {
        gaps.compactMap { gap in
            let usedPlaceIDs = Set(days.flatMap(\.stops).compactMap(\.placeId))
            let categories = preferredCategories(for: gap.type)
            let savedOptions = savedPlaces
                .filter { categories.contains($0.category) && !usedPlaceIDs.contains($0.id.uuidString) }
                .prefix(3)
                .map { place in
                    GapSuggestionOption(
                        id: "saved-\(place.id.uuidString)-\(gap.id)",
                        title: place.name,
                        subtitle: nonEmpty(place.address),
                        source: .confirmedSaved,
                        placeId: place.id.uuidString,
                        reviewCandidateId: nil,
                        mapCandidateId: nil,
                        reason: localized(
                            english: "Confirmed saved Map Stamp fits this gap.",
                            traditionalChinese: "已確認地圖章，適合補這個缺口。",
                            language: outputLanguage
                        ),
                        confidence: place.latitude != 0 || place.longitude != 0 ? .high : .medium,
                        action: .addToPlan
                    )
                }

            let reviewOptions = reviewCandidates
                .filter { candidate in
                    categories.contains(PlaceCategory.inferred(from: ([candidate.name, candidate.address] + candidate.evidence).joined(separator: " ")))
                }
                .prefix(3)
                .map { candidate in
                    let hasCoordinates = candidate.hasReliableCoordinates
                    return GapSuggestionOption(
                        id: "review-\(candidate.id.uuidString)-\(gap.id)",
                        title: candidate.name,
                        subtitle: nonEmpty(candidate.address),
                        source: hasCoordinates ? .reviewCandidate : .sourceClue,
                        placeId: nil,
                        reviewCandidateId: candidate.id.uuidString,
                        mapCandidateId: nil,
                        reason: hasCoordinates
                            ? localized(
                                english: "Review Candidate has map evidence but still needs confirmation.",
                                traditionalChinese: "待確認候選已有地圖證據，但仍要你確認。",
                                language: outputLanguage
                            )
                            : localized(
                                english: "Source clue needs recovery before it can become a stop.",
                                traditionalChinese: "來源線索要先查證，不能直接變成行程點。",
                                language: outputLanguage
                            ),
                        confidence: hasCoordinates ? .medium : .low,
                        action: hasCoordinates ? .reviewThenAdd : .resolveThenAdd
                    )
                }

            let externalOptions = mapCandidates
                .filter { candidate in
                    guard let category = candidate.category else { return true }
                    return categories.contains(category)
                }
                .prefix(3)
                .map { candidate in
                    GapSuggestionOption(
                        id: "external-\(candidate.id)-\(gap.id)",
                        title: candidate.title,
                        subtitle: nonEmpty(candidate.subtitle),
                        source: .externalSuggestion,
                        placeId: nil,
                        reviewCandidateId: nil,
                        mapCandidateId: candidate.id,
                        reason: localized(
                            english: "Public map candidate; approve before adding, and it will not be saved automatically.",
                            traditionalChinese: "公開地圖候選；加入前要先批准，而且不會自動存進記憶。",
                            language: outputLanguage
                        ),
                        confidence: candidate.latitude != 0 || candidate.longitude != 0 ? .medium : .low,
                        action: .addExternalWithApproval
                    )
                }

            let options = Array(savedOptions + reviewOptions + externalOptions)
            guard !options.isEmpty else { return nil }
            return GapSuggestion(
                id: "gap-suggestion-\(gap.id)",
                gapId: gap.id,
                dayId: gap.dayId,
                message: gap.message,
                options: options,
                requiresUserApproval: options.contains { $0.source == .externalSuggestion || $0.source == .reviewCandidate || $0.source == .sourceClue }
            )
        }
    }

    private func preferredCategories(for type: TripGap.GapType) -> Set<PlaceCategory> {
        switch type {
        case .missingBreakfast:
            return [.food, .cafe]
        case .missingLunch:
            return [.food]
        case .missingDinner:
            return [.food, .bar]
        case .missingCoffeeBreak:
            return [.cafe]
        case .missingAfternoonActivity:
            return [.attraction, .shopping, .cafe]
        case .missingEveningPlan:
            return [.bar, .food, .attraction]
        case .needsAreaCluster:
            return Set(PlaceCategory.allCases)
        case .needsRainBackup:
            return [.attraction, .shopping, .cafe]
        case .needsHoursCheck:
            return Set(PlaceCategory.allCases)
        }
    }

    private func localized(english: String, traditionalChinese: String, language: AppLanguage) -> String {
        switch language {
        case .english:
            return english
        case .traditionalChinese:
            return traditionalChinese
        }
    }

    private func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
