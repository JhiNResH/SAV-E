import SwiftUI

struct SaveMemoryBadge: View {
    enum State {
        case clue
        case ready
        case saved(PlaceCategory)
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

            if case .saved = state {
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
            case .saved(let category):
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
        case .saved(let category):
            return Color.saveStampColor(for: category)
        }
    }

    private var iconColor: Color {
        switch state {
        case .clue:
            return .saveInk
        case .ready:
            return .saveInk
        case .saved(let category):
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
            return "Map-ready place"
        case .saved:
            return "Saved memory card"
        }
    }
}

#Preview {
    HStack(spacing: 18) {
        SaveMemoryBadge(state: .clue)
        SaveMemoryBadge(state: .ready)
        SaveMemoryBadge(state: .saved(.food))
    }
    .padding()
    .background(SaveDottedBackground())
}
