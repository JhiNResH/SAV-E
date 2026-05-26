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
            Circle()
                .fill(fillColor)
                .overlay(
                    Circle()
                        .stroke(strokeColor, lineWidth: 1.2)
                )

            icon
                .font(.system(size: size * 0.34, weight: .black))
                .foregroundColor(iconColor)
        }
        .frame(width: size, height: size)
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
            return .saveCocoa
        case .ready:
            return .saveInk
        case .saved(let category):
            return Color.saveStampForeground(for: category)
        }
    }

    private var strokeColor: Color {
        switch state {
        case .clue:
            return Color.saveNotebookLine.opacity(0.45)
        case .ready:
            return Color.saveCocoa.opacity(0.22)
        case .saved:
            return Color.white.opacity(0.72)
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .clue:
            return "Clue"
        case .ready:
            return "Review Candidate"
        case .saved:
            return "Map Stamp"
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
