import SwiftUI

struct OnboardingView: View {
    @Environment(\.appLanguageSettings) private var languageSettings
    @Namespace private var proofNamespace
    @State private var stage: ProofStage
    @State private var clueText = ""
    @State private var selectedTags: Set<ProofIntentTag> = []
    private let autoUseSampleClue: Bool
    var onComplete: (String?) -> Void

    private var language: AppLanguage { languageSettings.language }
    private var isIntroStage: Bool { stage.introIndex != nil }

    init(startWithSampleProof: Bool = false, onComplete: @escaping (String?) -> Void) {
        _stage = State(initialValue: startWithSampleProof ? .clue : .lost)
        self.autoUseSampleClue = startWithSampleProof
        self.onComplete = onComplete
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompactHeight = proxy.size.height < 760
            let horizontalPadding: CGFloat = proxy.size.width < 380 ? 16 : 22
            let verticalSpacing: CGFloat = isCompactHeight ? 12 : 18

            onboardingContent(
                isCompactHeight: isCompactHeight,
                horizontalPadding: horizontalPadding,
                verticalSpacing: verticalSpacing
            )
        }
        .onAppear {
            if autoUseSampleClue && trimmedClue.isEmpty {
                useSampleClue()
            }
        }
    }

    private func onboardingContent(
        isCompactHeight: Bool,
        horizontalPadding: CGFloat,
        verticalSpacing: CGFloat
    ) -> some View {
        ZStack {
            SaveDottedBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: verticalSpacing) {
                    OnboardingCarouselTopBar(
                        stage: stage,
                        language: language,
                        onBack: goBack,
                        onChooseLanguage: chooseLanguage
                    )

                    if isIntroStage {
                        CarouselPromisePage(
                            stage: stage,
                            language: language,
                            isCompactHeight: isCompactHeight
                        )
                    } else if stage == .clue {
                        FirstPlaceInputPage(
                            clueText: $clueText,
                            language: language,
                            isCompactHeight: isCompactHeight,
                            onUseSample: useSampleClue
                        )
                    } else {
                        header(isCompactHeight: isCompactHeight)
                        AnimatedProofHero(
                            stage: stage,
                            clueText: clueText,
                            language: language,
                            namespace: proofNamespace,
                            height: isCompactHeight ? 178 : 214
                        )
                        ProofProgressRail(stage: stage, language: language)
                    }
                    if !isIntroStage && stage != .clue {
                        ProofStageCard(
                            stage: stage,
                            clueText: $clueText,
                            selectedTags: $selectedTags,
                            language: language,
                            isCompactHeight: isCompactHeight,
                            onUseSample: useSampleClue
                        )
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, isCompactHeight ? 8 : 28)
                .padding(.bottom, isCompactHeight ? 14 : 18)
                .frame(maxHeight: .infinity, alignment: .center)
                .clipped()

                bottomActions(isCompactHeight: isCompactHeight)
            }
        }
    }

    private func header(isCompactHeight: Bool) -> some View {
        VStack(spacing: isCompactHeight ? 8 : 12) {
            if !isCompactHeight {
                MemoMascotMark(size: 70, framed: false)
            }

            VStack(spacing: isCompactHeight ? 5 : 8) {
                Text(localized(
                    english: "Rescue one place before it disappears",
                    traditionalChinese: "先救回一個快忘掉的地點"
                ))
                .font(isCompactHeight ? .headline : .title2)
                .fontWeight(.black)
                .foregroundColor(.saveInk)
                .multilineTextAlignment(.center)

                Text(localized(
                    english: "Paste one messy clue. Memo finds the likely place and keeps proof until you confirm.",
                    traditionalChinese: "貼上一個混亂線索。Memo 會找出可能地點、保留證據，等你確認才保存。"
                ))
                .font(isCompactHeight ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                .lineSpacing(2)
                .foregroundColor(.saveMutedText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func bottomActions(isCompactHeight: Bool) -> some View {
        VStack(spacing: isCompactHeight ? 0 : 10) {
            Button(action: advance) {
                Text(primaryActionTitle)
                    .font(isCompactHeight ? .subheadline.weight(.black) : .headline.weight(.black))
                    .foregroundColor(primaryActionForeground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompactHeight ? 12 : 16)
                    .background(primaryActionFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.saveNotebookLine, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(stage == .clue && trimmedClue.isEmpty)
            .opacity(stage == .clue && trimmedClue.isEmpty ? 0.58 : 1)
            .padding(.horizontal, 24)

            if shouldShowSecondaryAction(isCompactHeight: isCompactHeight) {
                Button(secondaryActionTitle) {
                    skipCurrentStep()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.saveMutedText)
            }
        }
        .padding(.bottom, isCompactHeight ? 8 : 22)
        .background(Color.saveNotebookPage.opacity(0.72))
    }

    private var primaryActionTitle: String {
        switch stage {
        case .lost, .find, .privateMap:
            return localized(english: "Next", traditionalChinese: "下一步")
        case .clue:
            return localized(english: "Save my first place", traditionalChinese: "存下第一個地點")
        case .candidate:
            return localized(english: "Add to my map", traditionalChinese: "加到我的地圖")
        case .mapStamp:
            return localized(english: "Ask my saved places", traditionalChinese: "問我存過的地點")
        case .ask:
            return localized(english: "Add why it mattered", traditionalChinese: "補上為什麼重要")
        case .tag:
            return localized(english: "Open SAV-E", traditionalChinese: "打開 SAV-E")
        }
    }

    private var primaryActionFill: Color {
        switch stage {
        case .lost, .find, .privateMap: return .saveCoral
        case .clue, .candidate: return .saveHoney
        case .mapStamp: return .saveMint
        case .ask: return .saveSky
        case .tag: return .saveMint
        }
    }

    private var primaryActionForeground: Color {
        switch stage {
        case .lost, .find, .privateMap: return .white
        default: return .saveInk
        }
    }

    private var secondaryActionTitle: String {
        switch stage {
        case .tag:
            return localized(english: "Open SAV-E", traditionalChinese: "打開 SAV-E")
        default:
            return localized(english: "Skip this step", traditionalChinese: "跳過這一步")
        }
    }

    private var trimmedClue: String {
        clueText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func advance() {
        switch stage {
        case .lost:
            stage = .find
        case .find:
            stage = .privateMap
        case .privateMap:
            stage = .clue
        case .clue:
            guard !trimmedClue.isEmpty else { return }
            onComplete(trimmedClue)
        case .candidate:
            stage = .mapStamp
        case .mapStamp:
            stage = .ask
        case .ask:
            stage = .tag
        case .tag:
            onComplete(nil)
        }
    }

    private func skipCurrentStep() {
        switch stage {
        case .lost, .find, .privateMap:
            stage = .clue
        case .clue:
            onComplete(nil)
        case .candidate:
            stage = .mapStamp
        case .mapStamp:
            stage = .ask
        case .ask:
            stage = .tag
        case .tag:
            onComplete(nil)
        }
    }

    private func goBack() {
        switch stage {
        case .lost:
            break
        case .find:
            stage = .lost
        case .privateMap:
            stage = .find
        case .clue:
            stage = .privateMap
        case .candidate:
            stage = .clue
        case .mapStamp:
            stage = .candidate
        case .ask:
            stage = .mapStamp
        case .tag:
            stage = .ask
        }
    }

    private func shouldShowSecondaryAction(isCompactHeight: Bool) -> Bool {
        if stage == .tag { return false }
        if stage == .lost { return false }
        if stage == .clue { return true }
        return !isCompactHeight || stage.isIntroStage
    }

    private func useSampleClue() {
        clueText = localized(
            english: "Sample IG Reel: quiet cafe with a tiny patio near the station, tagged @hidden.moon.cafe",
            traditionalChinese: "範例 IG Reels：捷運站旁有小庭院的安靜咖啡店，標記 @hidden.moon.cafe"
        )
    }

    private func chooseLanguage(_ language: AppLanguage) {
        languageSettings.language = language
    }

    private func localized(english: String, traditionalChinese: String) -> String {
        switch language {
        case .english: return english
        case .traditionalChinese: return traditionalChinese
        }
    }
}

private enum ProofStage: Int, CaseIterable {
    case lost
    case find
    case privateMap
    case clue
    case candidate
    case mapStamp
    case ask
    case tag

    func title(language: AppLanguage) -> String {
        switch (self, language) {
        case (.lost, .english): return "Lost"
        case (.lost, .traditionalChinese): return "不再弄丟"
        case (.find, .english): return "Find"
        case (.find, .traditionalChinese): return "找出地點"
        case (.privateMap, .english): return "Map"
        case (.privateMap, .traditionalChinese): return "私人地圖"
        case (.clue, .english): return "Clue"
        case (.clue, .traditionalChinese): return "線索"
        case (.candidate, .english): return "Review"
        case (.candidate, .traditionalChinese): return "確認"
        case (.mapStamp, .english): return "Stamp"
        case (.mapStamp, .traditionalChinese): return "地圖章"
        case (.ask, .english): return "Ask"
        case (.ask, .traditionalChinese): return "提問"
        case (.tag, .english): return "Taste"
        case (.tag, .traditionalChinese): return "偏好"
        }
    }

    var introIndex: Int? {
        switch self {
        case .lost: return 0
        case .find: return 1
        case .privateMap: return 2
        default: return nil
        }
    }

    var isIntroStage: Bool {
        introIndex != nil
    }
}

private enum ProofIntentTag: String, CaseIterable {
    case coffee
    case dateNight
    case cheapEats
    case quiet
    case travel
    case friends

    func title(language: AppLanguage) -> String {
        switch (self, language) {
        case (.coffee, .english): return "Coffee"
        case (.coffee, .traditionalChinese): return "咖啡"
        case (.dateNight, .english): return "Date night"
        case (.dateNight, .traditionalChinese): return "約會"
        case (.cheapEats, .english): return "Cheap eats"
        case (.cheapEats, .traditionalChinese): return "平價美食"
        case (.quiet, .english): return "Quiet spot"
        case (.quiet, .traditionalChinese): return "安靜地點"
        case (.travel, .english): return "Trip idea"
        case (.travel, .traditionalChinese): return "旅行靈感"
        case (.friends, .english): return "Friend sent"
        case (.friends, .traditionalChinese): return "朋友推薦"
        }
    }
}

private struct OnboardingCarouselTopBar: View {
    let stage: ProofStage
    let language: AppLanguage
    let onBack: () -> Void
    let onChooseLanguage: (AppLanguage) -> Void

    private var currentIndex: Int {
        min(stage.rawValue, 3)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.black))
                    .foregroundColor(.saveInk)
                    .frame(width: 36, height: 36)
                    .background(Color.saveNotebookPage.opacity(stage == .lost ? 0.24 : 0.72))
                    .clipShape(Circle())
            }
            .opacity(stage == .lost ? 0.28 : 1)
            .disabled(stage == .lost)

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index == currentIndex ? Color.saveCoral : Color.saveNotebookLine.opacity(0.36))
                        .frame(width: index == currentIndex ? 28 : 9, height: 6)
                }
            }
            .accessibilityLabel("Onboarding step \(currentIndex + 1) of 4")

            Spacer()

            HStack(spacing: 4) {
                ForEach(AppLanguage.allCases) { option in
                    Button {
                        onChooseLanguage(option)
                    } label: {
                        Text(option == .english ? "EN" : "繁中")
                            .font(.caption2.weight(.black))
                            .foregroundColor(.saveInk)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                            .background(option == language ? Color.saveSky.opacity(0.62) : Color.saveNotebookPage.opacity(0.42))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel(option.displayName)
                }
            }
        }
    }
}

private struct CarouselPromisePage: View {
    let stage: ProofStage
    let language: AppLanguage
    let isCompactHeight: Bool

    var body: some View {
        VStack(spacing: isCompactHeight ? 16 : 24) {
            Spacer(minLength: 0)

            OnboardingCarouselVisual(
                stage: stage,
                language: language,
                height: isCompactHeight ? 228 : 300
            )

            VStack(spacing: isCompactHeight ? 8 : 12) {
                Text(headline)
                    .font(isCompactHeight ? .title2.weight(.black) : .largeTitle.weight(.black))
                    .foregroundColor(.saveInk)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(subtitle)
                    .font(isCompactHeight ? .subheadline.weight(.semibold) : .body.weight(.semibold))
                    .foregroundColor(.saveMutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .minimumScaleFactor(0.84)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
    }

    private var headline: String {
        switch stage {
        case .lost:
            return localized(english: "Keep the clue before it disappears.", traditionalChinese: "先把快消失的線索接住。")
        case .find:
            return localized(english: "SAV-E shows why it guessed.", traditionalChinese: "SAV-E 會說清楚為什麼這樣猜。")
        case .privateMap:
            return localized(english: "Confirm before it becomes memory.", traditionalChinese: "你確認後才變成記憶。")
        default:
            return ""
        }
    }

    private var subtitle: String {
        switch stage {
        case .lost:
            return localized(english: "Share a Reel, map link, caption, screenshot, or note. The raw source stays attached.", traditionalChinese: "Reel、地圖連結、文案、截圖或筆記都可以；原始來源會一起保留。")
        case .find:
            return localized(english: "Caption, handle, location words, and map evidence become a Review Candidate, not a fake pin.", traditionalChinese: "文案、帳號、地點字眼和地圖證據會變成待確認地點，不會直接假裝成地圖點。")
        case .privateMap:
            return localized(english: "Only confirmed places become private Map Stamps you can ask about later.", traditionalChinese: "只有你確認過的地點，才會成為之後能詢問的私人地圖章。")
        default:
            return ""
        }
    }

    private func localized(english: String, traditionalChinese: String) -> String {
        switch language {
        case .english: return english
        case .traditionalChinese: return traditionalChinese
        }
    }
}

private struct OnboardingCarouselVisual: View {
    let stage: ProofStage
    let language: AppLanguage
    let height: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 54, style: .continuous)
                .fill(Color.saveNotebookPage.opacity(0.28))
                .frame(width: height * 0.86, height: height * 0.72)
                .rotationEffect(.degrees(-7))

            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(Color.saveSky.opacity(0.18))
                .frame(width: height * 0.72, height: height * 0.62)
                .offset(x: 28, y: -8)

            switch stage {
            case .lost:
                lostVisual
            case .find:
                findVisual
            case .privateMap:
                privateMapVisual
            default:
                MemoMascotMark(size: height * 0.34, framed: true)
            }
        }
        .frame(height: height)
    }

    private var lostVisual: some View {
        ZStack {
            floatingSource(label: "CHAT", icon: "bubble.left.and.bubble.right.fill", tint: .saveSky)
                .offset(x: -height * 0.28, y: -height * 0.22)
                .rotationEffect(.degrees(-8))

            floatingSource(label: "IG", icon: "camera.fill", tint: .saveBlush)
                .offset(x: height * 0.27, y: -height * 0.20)
                .rotationEffect(.degrees(9))

            floatingSource(label: "MAP", icon: "map.fill", tint: .saveMint)
                .offset(x: -height * 0.24, y: height * 0.23)
                .rotationEffect(.degrees(7))

            Image(systemName: "arrow.down")
                .font(.title.weight(.black))
                .foregroundColor(.saveInk.opacity(0.46))
                .offset(y: -6)

            MemoMascotMark(size: height * 0.32, framed: true)
                .offset(x: height * 0.18, y: height * 0.18)
        }
    }

    private var findVisual: some View {
        ZStack {
            clueCard
                .offset(x: -height * 0.14, y: -height * 0.16)
                .rotationEffect(.degrees(-7))

            Image(systemName: "sparkles")
                .font(.largeTitle.weight(.black))
                .foregroundColor(.saveHoney)
                .offset(x: height * 0.11, y: -height * 0.03)

            candidateCard
                .offset(x: height * 0.08, y: height * 0.17)
                .rotationEffect(.degrees(5))

            MemoMascotMark(size: height * 0.22, framed: true)
                .offset(x: height * 0.24, y: -height * 0.22)
        }
    }

    private var privateMapVisual: some View {
        ZStack {
            SaveMiniMap(language: language)
                .frame(width: height * 0.82, height: height * 0.58)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: Color.saveInk.opacity(0.10), radius: 18, x: 0, y: 12)

            VStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.headline.weight(.black))
                Text(localized(english: "Private", traditionalChinese: "私人"))
                    .font(.caption.weight(.black))
            }
            .foregroundColor(.saveInk)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.saveHoney.opacity(0.88))
            .clipShape(Capsule())
            .offset(x: height * 0.22, y: -height * 0.23)

            MemoMascotMark(size: height * 0.22, framed: true)
                .offset(x: -height * 0.26, y: height * 0.22)
        }
    }

    private var clueCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "quote.bubble.fill")
                Text(localized(english: "Friend sent", traditionalChinese: "朋友傳來"))
            }
            .font(.caption.weight(.black))
            .foregroundColor(.saveMutedText)

            Text(localized(english: "quiet cafe near the station", traditionalChinese: "捷運站旁安靜咖啡"))
                .font(.headline.weight(.black))
                .foregroundColor(.saveInk)
        }
        .padding(14)
        .frame(width: height * 0.58, alignment: .leading)
        .background(Color.saveNotebookPage.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.saveNotebookLine.opacity(0.38), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var candidateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.saveMint)
                Text(localized(english: "Likely place", traditionalChinese: "可能地點"))
                    .foregroundColor(.saveMutedText)
            }
            .font(.caption.weight(.black))

            Text(localized(english: "Hidden Moon Cafe?", traditionalChinese: "Hidden Moon Cafe？"))
                .font(.headline.weight(.black))
                .foregroundColor(.saveInk)

            Label(localized(english: "source kept", traditionalChinese: "保留來源"), systemImage: "link")
                .font(.caption.weight(.black))
                .foregroundColor(.saveInk)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.saveSky.opacity(0.46))
                .clipShape(Capsule())
        }
        .padding(14)
        .frame(width: height * 0.66, alignment: .leading)
        .background(Color.saveNotebookPage.opacity(0.96))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.saveNotebookLine.opacity(0.42), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func floatingSource(label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
            Text(label)
                .font(.caption2.weight(.black))
        }
        .foregroundColor(.saveInk)
        .frame(width: height * 0.24, height: height * 0.20)
        .background(tint.opacity(0.76))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.saveNotebookLine.opacity(0.30), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.saveInk.opacity(0.08), radius: 12, x: 0, y: 7)
    }

    private func localized(english: String, traditionalChinese: String) -> String {
        switch language {
        case .english: return english
        case .traditionalChinese: return traditionalChinese
        }
    }
}

private struct FirstPlaceInputPage: View {
    @Binding var clueText: String
    let language: AppLanguage
    let isCompactHeight: Bool
    let onUseSample: () -> Void

    var body: some View {
        VStack(spacing: isCompactHeight ? 14 : 20) {
            Spacer(minLength: 0)

            MemoMascotMark(size: isCompactHeight ? 74 : 94, framed: false)
                .shadow(color: Color.saveInk.opacity(0.10), radius: 18, x: 0, y: 10)

            VStack(spacing: isCompactHeight ? 7 : 10) {
                Text(localized(english: "Rescue one place now", traditionalChinese: "現在救回一個地點"))
                    .font(isCompactHeight ? .title2.weight(.black) : .largeTitle.weight(.black))
                    .foregroundColor(.saveInk)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(localized(
                    english: "Paste one clue. Memo will keep the source and wait for your confirmation.",
                    traditionalChinese: "貼上一個線索。Memo 會保留來源，等你確認後才保存。"
                ))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.saveMutedText)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .lineLimit(3)
                .minimumScaleFactor(0.84)
            }

            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.saveNotebookPage.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.saveNotebookLine.opacity(0.46), lineWidth: 1.5)
                        )

                    TextEditor(text: $clueText)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.saveInk)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(minHeight: isCompactHeight ? 138 : 162)

                    if clueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(localized(
                            english: "Example: IG Reel caption says quiet cafe near the station, tagged @hidden.moon.cafe...",
                            traditionalChinese: "例如：IG Reels 文案寫捷運站旁安靜咖啡，標記 @hidden.moon.cafe..."
                        ))
                        .font(.body.weight(.semibold))
                        .foregroundColor(.saveMutedText.opacity(0.72))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                    }
                }

                Button(action: onUseSample) {
                    Label(localized(english: "Try sample clue", traditionalChinese: "試用範例線索"), systemImage: "wand.and.stars")
                        .font(.subheadline.weight(.black))
                        .foregroundColor(.saveInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.saveHoney.opacity(0.54))
                        .overlay(Capsule().stroke(Color.saveNotebookLine.opacity(0.50), lineWidth: 1))
                        .clipShape(Capsule())
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
    }

    private func localized(english: String, traditionalChinese: String) -> String {
        switch language {
        case .english: return english
        case .traditionalChinese: return traditionalChinese
        }
    }
}

private struct AnimatedProofHero: View {
    let stage: ProofStage
    let clueText: String
    let language: AppLanguage
    let namespace: Namespace.ID
    let height: CGFloat

    @State private var isFloating = false
    @State private var scanOffset: CGFloat = -92

    private var progress: CGFloat {
        CGFloat(stage.rawValue) / CGFloat(max(ProofStage.allCases.count - 1, 1))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.saveNotebookPage.opacity(0.96),
                            Color.saveNotebookPage.opacity(0.74)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.saveNotebookLine.opacity(0.62), lineWidth: 1.5)
                )

            SaveProofRouteShape(progress: progress)
                .stroke(Color.saveNotebookLine.opacity(0.18), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                .padding(.horizontal, 28)
                .padding(.vertical, 34)

            SaveProofRouteShape(progress: progress)
                .trim(from: 0, to: min(1, max(0.08, progress + 0.08)))
                .stroke(Color.saveHoney.opacity(0.78), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .padding(.horizontal, 28)
                .padding(.vertical, 34)

            proofContent
                .padding(16)

            if stage == .clue || stage == .candidate {
                scanningBand
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.saveInk.opacity(0.08), radius: 16, x: 0, y: 10)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) {
                isFloating = true
            }
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                scanOffset = 120
            }
        }
        .animation(.spring(response: 0.52, dampingFraction: 0.82), value: stage)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var proofContent: some View {
        switch stage {
        case .lost, .find, .privateMap, .clue:
            messySignalView
        case .candidate:
            reviewCandidateView
        case .mapStamp:
            mapStampView
        case .ask, .tag:
            askMemoryView
        }
    }

    private var messySignalView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                SourceBubble(label: "IG", tint: .savePink, offsetY: isFloating ? -4 : 4)
                SourceBubble(label: "TT", tint: .saveSky, offsetY: isFloating ? 5 : -3)
                SourceBubble(label: "MAP", tint: .saveMint, offsetY: isFloating ? -2 : 5)
                Spacer()
                Image(systemName: "arrow.down.forward.circle.fill")
                    .font(.title2.weight(.black))
                    .foregroundColor(.saveInk.opacity(0.62))
            }

            VStack(alignment: .leading, spacing: 9) {
                Text(localized(english: "Messy place signal", traditionalChinese: "混亂地點線索"))
                    .font(.caption)
                    .fontWeight(.black)
                    .textCase(.uppercase)
                    .foregroundColor(.saveMutedText)

                Text(signalLine)
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.saveInk)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    miniChip(localized(english: "caption", traditionalChinese: "文案"), tint: .saveHoney)
                    miniChip(localized(english: "friend tip", traditionalChinese: "朋友推薦"), tint: .saveSky)
                    miniChip(localized(english: "needs proof", traditionalChinese: "待確認"), tint: .saveMint)
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.saveNotebookPage.opacity(0.52))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.saveNotebookLine.opacity(0.34), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .matchedGeometryEffect(id: "proof-card", in: namespace)
        }
    }

    private var reviewCandidateView: some View {
        HStack(alignment: .top, spacing: 14) {
            stageIcon(systemImage: "checklist.unchecked", tint: .saveHoney)

            VStack(alignment: .leading, spacing: 10) {
                Text(localized(english: "Review Candidate", traditionalChinese: "待確認地點"))
                    .font(.caption)
                    .fontWeight(.black)
                    .textCase(.uppercase)
                    .foregroundColor(.saveMutedText)

                Text(localized(english: "Hidden Moon Cafe?", traditionalChinese: "Hidden Moon Cafe？"))
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundColor(.saveInk)

                ProofHeroLine(icon: "checkmark.seal.fill", text: localized(english: "Name clue found", traditionalChinese: "找到名稱線索"), tint: .saveMint)
                ProofHeroLine(icon: "link", text: localized(english: "Source kept", traditionalChinese: "保留來源"), tint: .saveSky)
                ProofHeroLine(icon: "exclamationmark.triangle.fill", text: localized(english: "Needs exact address", traditionalChinese: "還缺精確地址"), tint: .saveHoney)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.saveNotebookPage.opacity(0.52))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.saveNotebookLine.opacity(0.42), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .matchedGeometryEffect(id: "proof-card", in: namespace)
    }

    private var mapStampView: some View {
        ZStack(alignment: .bottomLeading) {
            SaveMiniMap(language: language)

            HStack(spacing: 12) {
                stageIcon(systemImage: "mappin.and.ellipse", tint: .saveMint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(localized(english: "Map Stamp saved", traditionalChinese: "已存成地圖章"))
                        .font(.caption)
                        .fontWeight(.black)
                        .textCase(.uppercase)
                        .foregroundColor(.saveMutedText)

                    Text(localized(english: "Hidden Moon Cafe", traditionalChinese: "Hidden Moon Cafe"))
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.saveInk)

                    Text(localized(english: "Coffee · source kept · private", traditionalChinese: "咖啡 · 保留來源 · 私人"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.saveMutedText)
                }

                Spacer()
            }
            .padding(14)
            .background(Color.saveNotebookPage.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .matchedGeometryEffect(id: "proof-card", in: namespace)
        }
    }

    private var askMemoryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                stageIcon(systemImage: "sparkles", tint: .saveSky)
                VStack(alignment: .leading, spacing: 3) {
                    Text(localized(english: "Ask saved memory", traditionalChinese: "詢問已存記憶"))
                        .font(.caption)
                        .fontWeight(.black)
                        .textCase(.uppercase)
                        .foregroundColor(.saveMutedText)
                    Text(localized(english: "Saved-first answer", traditionalChinese: "先用你的記憶回答"))
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.saveInk)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(localized(english: "Recommend nearby coffee", traditionalChinese: "推薦附近咖啡"))
                    .font(.subheadline)
                    .fontWeight(.black)
                    .foregroundColor(.saveInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.saveHoney.opacity(0.42))
                    .clipShape(Capsule())

                Text(localized(
                    english: "Start with the place you confirmed. It matches your saved coffee clue; public nearby options stay separate.",
                    traditionalChinese: "先從你確認過的地點開始。它符合你存下的咖啡線索；附近公開選項會分開。"
                ))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.saveInk)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.saveMint.opacity(0.42))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.saveNotebookPage.opacity(0.52))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.saveNotebookLine.opacity(0.42), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .matchedGeometryEffect(id: "proof-card", in: namespace)
    }

    private var scanningBand: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.saveNotebookPage.opacity(0.34),
                        Color.saveSky.opacity(0.24),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 80)
            .rotationEffect(.degrees(12))
            .offset(x: scanOffset)
            .allowsHitTesting(false)
    }

    private var signalLine: String {
        let trimmed = clueText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return localized(
                english: "Sample Reel: quiet cafe near the station",
                traditionalChinese: "範例 Reels：捷運站旁安靜咖啡"
            )
        }
        return String(trimmed.prefix(74))
    }

    private func stageIcon(systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(.title3.weight(.black))
            .foregroundColor(.saveInk)
            .frame(width: 48, height: 48)
            .background(tint.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.saveNotebookLine.opacity(0.46), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func miniChip(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.black)
            .foregroundColor(.saveInk)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.50))
            .clipShape(Capsule())
    }

    private func localized(english: String, traditionalChinese: String) -> String {
        switch language {
        case .english: return english
        case .traditionalChinese: return traditionalChinese
        }
    }

    private var accessibilityLabel: String {
        switch language {
        case .english:
            return "Animated SAV-E proof flow showing \(stage.title(language: language))"
        case .traditionalChinese:
            return "SAV-E 動態流程，目前是\(stage.title(language: language))"
        }
    }
}

private struct SourceBubble: View {
    let label: String
    let tint: Color
    let offsetY: CGFloat

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.black)
            .foregroundColor(.saveInk)
            .frame(width: label.count > 2 ? 42 : 34, height: 34)
            .background(tint.opacity(0.84))
            .overlay(Circle().stroke(Color.saveNotebookBackground.opacity(0.82), lineWidth: 2))
            .clipShape(Circle())
            .offset(y: offsetY)
    }
}

private struct ProofHeroLine: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.black))
                .foregroundColor(.saveInk)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.58))
                .clipShape(Circle())

            Text(text)
                .font(.caption)
                .fontWeight(.black)
                .foregroundColor(.saveInk)
        }
    }
}

private struct SaveMiniMap: View {
    let language: AppLanguage

    var body: some View {
        ZStack {
            Color.saveMint.opacity(0.28)

            Path { path in
                path.move(to: CGPoint(x: 20, y: 40))
                path.addLine(to: CGPoint(x: 130, y: 96))
                path.addLine(to: CGPoint(x: 250, y: 54))
                path.move(to: CGPoint(x: 38, y: 156))
                path.addLine(to: CGPoint(x: 156, y: 88))
                path.addLine(to: CGPoint(x: 300, y: 170))
            }
            .stroke(Color.saveNotebookLine.opacity(0.22), style: StrokeStyle(lineWidth: 10, lineCap: .round))

            ForEach(SaveMiniMapPin.sample) { pin in
                VStack(spacing: 3) {
                    Image(systemName: pin.icon)
                        .font(.caption.weight(.black))
                        .foregroundColor(.saveInk)
                        .frame(width: pin.isPrimary ? 38 : 30, height: pin.isPrimary ? 38 : 30)
                        .background(pin.tint.opacity(0.88))
                        .overlay(Circle().stroke(Color.saveNotebookBackground.opacity(0.82), lineWidth: 2))
                        .clipShape(Circle())

                    if pin.isPrimary {
                        Text(language.localized(english: "Map Stamp", traditionalChinese: "地圖章"))
                            .font(.caption2)
                            .fontWeight(.black)
                            .foregroundColor(.saveInk)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.saveNotebookPage.opacity(0.88))
                            .clipShape(Capsule())
                    }
                }
                .position(pin.position)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct SaveMiniMapPin: Identifiable {
    let id = UUID()
    let icon: String
    let tint: Color
    let position: CGPoint
    let isPrimary: Bool

    static let sample: [SaveMiniMapPin] = [
        SaveMiniMapPin(icon: "cup.and.saucer.fill", tint: .saveHoney, position: CGPoint(x: 106, y: 92), isPrimary: true),
        SaveMiniMapPin(icon: "fork.knife", tint: .saveSky, position: CGPoint(x: 236, y: 48), isPrimary: false),
        SaveMiniMapPin(icon: "camera.fill", tint: .savePink, position: CGPoint(x: 268, y: 142), isPrimary: false)
    ]
}

private struct SaveProofRouteShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.70))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.46, y: rect.minY + rect.height * 0.36),
            control1: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.36),
            control2: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.78)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.28),
            control1: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.minY + rect.height * 0.06),
            control2: CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.58)
        )
        return path
    }
}

private struct ProofProgressRail: View {
    let stage: ProofStage
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProofStage.allCases, id: \.self) { item in
                VStack(spacing: 7) {
                    Circle()
                        .fill(fill(for: item))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.saveNotebookLine.opacity(0.72), lineWidth: 1)
                        )
                        .overlay {
                            if item.rawValue < stage.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.black))
                                    .foregroundColor(.saveInk)
                            }
                        }

                    Text(item.title(language: language))
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundColor(item.rawValue <= stage.rawValue ? .saveInk : .saveMutedText.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.56)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)

                if item != ProofStage.allCases.last {
                    Rectangle()
                        .fill(item.rawValue < stage.rawValue ? Color.saveHoney : Color.saveNotebookLine.opacity(0.34))
                        .frame(height: 2)
                        .padding(.horizontal, 2)
                        .offset(y: -13)
                }
            }
        }
        .padding(.horizontal, 2)
        .accessibilityLabel(accessibilityLabel)
    }

    private func fill(for item: ProofStage) -> Color {
        if item.rawValue < stage.rawValue { return .saveHoney }
        if item == stage { return .saveSky }
        return .saveNotebookPage
    }

    private var accessibilityLabel: String {
        switch language {
        case .english:
            return "Onboarding step \(stage.rawValue + 1) of \(ProofStage.allCases.count)"
        case .traditionalChinese:
            return "新手設定第 \(stage.rawValue + 1) 步，共 \(ProofStage.allCases.count) 步"
        }
    }
}

private struct ProofStageCard: View {
    let stage: ProofStage
    @Binding var clueText: String
    @Binding var selectedTags: Set<ProofIntentTag>
    let language: AppLanguage
    let isCompactHeight: Bool
    let onUseSample: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: isCompactHeight ? 13 : 18) {
            stageHeader
            stageContent
        }
        .padding(isCompactHeight ? 16 : 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.saveNotebookPage.opacity(0.96))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.saveNotebookLine, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.saveInk.opacity(0.08), radius: 16, x: 0, y: 10)
    }

    private var stageHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font((isCompactHeight ? Font.headline : Font.title2).weight(.black))
                .foregroundColor(.saveInk)
                .frame(width: isCompactHeight ? 38 : 44, height: isCompactHeight ? 38 : 44)
                .background(headerTint.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.saveNotebookLine.opacity(0.62), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(isCompactHeight ? .headline : .title3)
                    .fontWeight(.black)
                    .foregroundColor(.saveInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(isCompactHeight ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundColor(.saveMutedText)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var stageContent: some View {
        switch stage {
        case .lost, .find, .privateMap:
            EmptyView()
        case .clue:
            clueInput
        case .candidate:
            candidateProof
        case .mapStamp:
            mapStampProof
        case .ask:
            askProof
        case .tag:
            tagProof
        }
    }

    private var clueInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.saveNotebookPage.opacity(0.62))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.saveNotebookLine.opacity(0.44), lineWidth: 1)
                    )

                TextEditor(text: $clueText)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.saveInk)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: 116)

                if clueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.saveMutedText.opacity(0.72))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 116)

            Button(action: onUseSample) {
                Label(sampleTitle, systemImage: "sparkles")
                    .font(.subheadline.weight(.black))
                    .foregroundColor(.saveInk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.saveHoney.opacity(0.48))
                    .overlay(Capsule().stroke(Color.saveNotebookLine.opacity(0.58), lineWidth: 1))
                    .clipShape(Capsule())
            }
        }
    }

    private var candidateProof: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProofLine(
                label: localized(english: "Found", traditionalChinese: "找到"),
                value: localized(english: "Hidden Moon Cafe? from the sample handle", traditionalChinese: "從範例帳號猜到 Hidden Moon Cafe？"),
                icon: "checkmark.seal.fill",
                tint: .saveMint
            )
            ProofLine(
                label: localized(english: "Source", traditionalChinese: "來源"),
                value: sourceSummary,
                icon: "link",
                tint: .saveSky
            )
            ProofLine(
                label: localized(english: "Missing", traditionalChinese: "還缺"),
                value: localized(english: "Exact address and coordinates before saving", traditionalChinese: "保存前要確認精確地址與座標"),
                icon: "exclamationmark.triangle.fill",
                tint: .saveHoney
            )

            Text(localized(
                english: "This stays in Review until you confirm the exact place.",
                traditionalChinese: "這會先留在待確認，等你確認正確地點後再保存。"
            ))
            .font(.footnote)
            .fontWeight(.bold)
            .foregroundColor(.saveMutedText)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var mapStampProof: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2.weight(.black))
                    .foregroundColor(.saveInk)
                    .frame(width: 56, height: 56)
                    .background(Color.saveMint.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Hidden Moon Cafe")
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(.saveInk)

                    Text(localized(english: "Map Stamp · Coffee · Source kept", traditionalChinese: "地圖章 · 咖啡 · 保留來源"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.saveMutedText)
                }
            }

            HStack(spacing: 10) {
                chip(localized(english: "confirmed", traditionalChinese: "已確認"), tint: .saveMint)
                chip(localized(english: "source kept", traditionalChinese: "保留來源"), tint: .saveSky)
                chip(localized(english: "private", traditionalChinese: "私人"), tint: .saveHoney)
            }
        }
    }

    private var askProof: some View {
        VStack(alignment: .leading, spacing: 12) {
            chatBubble(
                localized(english: "Recommend nearby coffee from my saved places", traditionalChinese: "從我存過的地方推薦附近咖啡"),
                isUser: true
            )
            chatBubble(
                localized(
                    english: "I’d start with Hidden Moon Cafe because you confirmed it from the sample clue. Public discovery stays separate.",
                    traditionalChinese: "我會先推薦 Hidden Moon Cafe，因為你剛用範例線索確認過它。公開搜尋會另外標示。"
                ),
                isUser: false
            )
        }
    }

    private var tagProof: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localized(
                english: "Now tell SAV-E why this mattered. These tags should come after proof, not before.",
                traditionalChinese: "現在再告訴 SAV-E 為什麼你想存。這些標籤應該在證明有用後才出現。"
            ))
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundColor(.saveMutedText)
            .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                ForEach(ProofIntentTag.allCases, id: \.self) { tag in
                    Button {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    } label: {
                        Label(tag.title(language: language), systemImage: selectedTags.contains(tag) ? "checkmark.circle.fill" : "circle")
                            .font(.subheadline.weight(.black))
                            .foregroundColor(.saveInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(selectedTags.contains(tag) ? Color.saveHoney.opacity(0.64) : Color.saveNotebookPage.opacity(0.54))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.saveNotebookLine.opacity(0.48), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }

            UpgradePreviewCard(language: language, isCompactHeight: isCompactHeight)
        }
    }

    private func chip(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.black)
            .foregroundColor(.saveInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.58))
            .clipShape(Capsule())
    }

    private func chatBubble(_ text: String, isUser: Bool) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.saveInk)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .background(isUser ? Color.saveHoney.opacity(0.42) : Color.saveMint.opacity(0.42))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var iconName: String {
        switch stage {
        case .lost, .find, .privateMap: return "wand.and.stars"
        case .clue: return "square.and.pencil"
        case .candidate: return "checklist.unchecked"
        case .mapStamp: return "mappin.and.ellipse"
        case .ask: return "sparkles"
        case .tag: return "tag.fill"
        }
    }

    private var headerTint: Color {
        switch stage {
        case .lost, .find, .privateMap: return .saveHoney
        case .clue, .candidate: return .saveHoney
        case .mapStamp: return .saveMint
        case .ask: return .saveSky
        case .tag: return .savePink
        }
    }

    private var title: String {
        switch stage {
        case .lost, .find, .privateMap:
            return localized(english: "Start with one rescue mission", traditionalChinese: "先完成一次救回地點任務")
        case .clue:
            return localized(english: "Paste the clue you almost lost", traditionalChinese: "貼上快被你忘掉的線索")
        case .candidate:
            return localized(english: "Check the likely place", traditionalChinese: "確認可能的地點")
        case .mapStamp:
            return localized(english: "Stamp it onto your map", traditionalChinese: "蓋到你的地圖上")
        case .ask:
            return localized(english: "Ask your saved places first", traditionalChinese: "先問你存過的地點")
        case .tag:
            return localized(english: "Tell Memo why it mattered", traditionalChinese: "告訴 Memo 為什麼重要")
        }
    }

    private var subtitle: String {
        switch stage {
        case .lost, .find, .privateMap:
            return localized(
                english: "One clue becomes one confirmed private place. Change language here if you need to.",
                traditionalChinese: "一個線索會變成一個確認過的私人地點。需要的話，也可以在這裡切換語言。"
            )
        case .clue:
            return localized(english: "Use a Reel caption, map link, screenshot text, or friend message.", traditionalChinese: "可以用短影音文案、地圖連結、截圖文字或朋友訊息。")
        case .candidate:
            return localized(english: "Memo shows what it found and what still needs your confirmation.", traditionalChinese: "Memo 會顯示找到什麼，以及還需要你確認什麼。")
        case .mapStamp:
            return localized(english: "Only confirmed places become private map memory.", traditionalChinese: "只有確認後，才會變成你的私人地圖記憶。")
        case .ask:
            return localized(english: "SAV-E starts with your saved place, then keeps public discovery separate.", traditionalChinese: "SAV-E 會先用你存過的地點回答，再分開標示公開搜尋。")
        case .tag:
            return localized(english: "A few tags help future answers remember why you saved it.", traditionalChinese: "用幾個標籤，讓之後的回答記得你為什麼想存。")
        }
    }

    private var placeholder: String {
        localized(
            english: "Example: IG Reel caption says quiet cafe near the station, tagged @hidden.moon.cafe...",
            traditionalChinese: "例如：IG Reels 文案寫捷運站旁安靜咖啡，標記 @hidden.moon.cafe..."
        )
    }

    private var sampleTitle: String {
        localized(english: "Use sample clue", traditionalChinese: "使用範例線索")
    }

    private var sourceSummary: String {
        let trimmed = clueText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return localized(english: "Friend message", traditionalChinese: "朋友訊息")
        }
        return String(trimmed.prefix(72))
    }

    private func localized(english: String, traditionalChinese: String) -> String {
        switch language {
        case .english: return english
        case .traditionalChinese: return traditionalChinese
        }
    }
}

private struct UpgradePreviewCard: View {
    let language: AppLanguage
    let isCompactHeight: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompactHeight ? 10 : 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.headline.weight(.black))
                    .foregroundColor(.saveInk)
                    .frame(width: 36, height: 36)
                    .background(Color.saveLavender.opacity(0.58))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(localized(english: "Upgrade after the first useful memory", traditionalChinese: "先有第一個有用記憶，再升級"))
                        .font(.caption.weight(.black))
                        .foregroundColor(.saveInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.84)

                    Text(localized(english: "Start free. Pro is for heavier recovery and planning.", traditionalChinese: "先免費開始。進階版留給更重的找地點與規劃。"))
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.saveMutedText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }
            }

            HStack(spacing: 10) {
                planColumn(
                    title: localized(english: "Free", traditionalChinese: "免費"),
                    subtitle: localized(english: "Save, review, ask", traditionalChinese: "保存、確認、提問"),
                    systemImage: "checkmark.seal.fill",
                    tint: .saveMint
                )

                planColumn(
                    title: localized(english: "SAV-E Pro", traditionalChinese: "SAV-E 進階版"),
                    subtitle: localized(english: "OCR, recovery, planning", traditionalChinese: "截圖辨識、找回地點、規劃"),
                    systemImage: "lock.open.fill",
                    tint: .saveHoney
                )
            }
        }
        .padding(isCompactHeight ? 12 : 14)
        .background(
            LinearGradient(
                colors: [
                    Color.saveLavender.opacity(0.18),
                    Color.saveBlush.opacity(0.44),
                    Color.saveNotebookPage.opacity(0.68)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.saveNotebookLine.opacity(0.38), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func planColumn(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.black))
                .foregroundColor(.saveInk)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.62))
                .clipShape(Circle())

            Text(title)
                .font(.caption.weight(.black))
                .foregroundColor(.saveInk)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(subtitle)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.saveMutedText)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.saveNotebookPage.opacity(0.58))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.saveNotebookLine.opacity(0.24), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func localized(english: String, traditionalChinese: String) -> String {
        switch language {
        case .english: return english
        case .traditionalChinese: return traditionalChinese
        }
    }
}

private struct ProofLine: View {
    let label: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.black))
                .foregroundColor(.saveInk)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.64))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(label.uppercased())
                    .font(.caption2)
                    .fontWeight(.black)
                    .foregroundColor(.saveMutedText)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.saveInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct FirstRunTrustNote: View {
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.black))
                .foregroundColor(.saveInk)

            Text(text)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.saveMutedText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.saveNotebookPage.opacity(0.74))
        .overlay(
            Capsule()
                .stroke(Color.saveNotebookLine.opacity(0.38), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private var text: String {
        switch language {
        case .english: return "Private food + travel memory, not public reviews."
        case .traditionalChinese: return "這是私人的美食與旅行記憶，不是公開評論。"
        }
    }
}

#Preview {
    OnboardingView { _ in }
        .environment(\.appLanguageSettings, AppLanguageSettings())
}
