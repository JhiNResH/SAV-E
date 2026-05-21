import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    var onComplete: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "pawprint.fill",
            title: "Save spots while you scroll",
            subtitle: "Share an IG post, map link, screenshot, or note. SAV-E will sniff for the real place.",
            color: .saveBerry
        ),
        OnboardingPage(
            icon: "bird.fill",
            title: "No more fake pins",
            subtitle: "If SAV-E is unsure, it keeps the clue in Review until you confirm it.",
            color: .saveHoney
        ),
        OnboardingPage(
            icon: "suitcase.rolling.fill",
            title: "Turn memories into trips",
            subtitle: "Your confirmed spots become a private travel memory SAV-E can plan from.",
            color: Color(hex: "5B8FA8")
        ),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: 30) {
                        Spacer()

                        ZStack {
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(pages[index].color.opacity(0.14))
                                .frame(width: 132, height: 132)

                            Image(systemName: pages[index].icon)
                                .font(.system(size: 64, weight: .semibold))
                                .foregroundColor(pages[index].color)
                        }

                        VStack(spacing: 12) {
                            Text(pages[index].title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.wanderlyCharcoal)
                                .multilineTextAlignment(.center)

                            Text(pages[index].subtitle)
                                .font(.subheadline)
                                .lineSpacing(3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Bottom controls
            VStack(spacing: 0) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.saveBerry : Color.saveBerry.opacity(0.26))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        onComplete()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Start with SAV-E")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.saveBerry)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        onComplete()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color.saveBlush, Color.saveCream, Color.saveMint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

#Preview {
    OnboardingView(onComplete: {})
}
