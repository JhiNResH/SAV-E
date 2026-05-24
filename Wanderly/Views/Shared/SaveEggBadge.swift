import SwiftUI

struct SaveEggBadge: View {
    enum State {
        case clue
        case ready
        case hatched(PlaceCategory)
    }

    let state: State
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(Color.saveNotebookLine.opacity(0.9), lineWidth: 1.3)
                )

            if case .hatched = state {
                cardTabs
            }

            icon
                .font(.system(size: size * 0.34, weight: .black))
                .foregroundColor(iconColor)
        }
        .frame(width: size, height: size * 0.88)
        .accessibilityLabel(accessibilityLabel)
    }

    private var icon: some View {
        Group {
            switch state {
            case .clue:
                Image(systemName: "link")
            case .ready:
                Image(systemName: "seal.fill")
            case .hatched(let category):
                Image(systemName: category.iconName)
            }
        }
    }

    private var fillColor: Color {
        switch state {
        case .clue:
            return .saveNotebookPage
        case .ready:
            return .saveHoney
        case .hatched(let category):
            return Color.saveStampColor(for: category)
        }
    }

    private var iconColor: Color {
        switch state {
        case .clue:
            return .saveInk
        case .ready:
            return .saveInk
        case .hatched(let category):
            return Color.saveStampForeground(for: category)
        }
    }

    private var cardTabs: some View {
        HStack(spacing: size * 0.04) {
            ForEach([Color.saveSky, Color.saveHoney, Color.savePink], id: \.self) { color in
                RoundedRectangle(cornerRadius: size * 0.035, style: .continuous)
                    .fill(color)
                    .frame(width: size * 0.12, height: size * 0.56)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.035, style: .continuous)
                            .stroke(Color.saveNotebookLine.opacity(0.55), lineWidth: 0.8)
                    )
            }
        }
        .offset(x: size * 0.25)
        .allowsHitTesting(false)
    }

    private var accessibilityLabel: String {
        switch state {
        case .clue:
            return "Place clue"
        case .ready:
            return "Ready to save"
        case .hatched:
            return "Saved memory card"
        }
    }
}

#Preview {
    HStack(spacing: 18) {
        SaveEggBadge(state: .clue)
        SaveEggBadge(state: .ready)
        SaveEggBadge(state: .hatched(.food))
    }
    .padding()
    .background(SaveDottedBackground())
}
