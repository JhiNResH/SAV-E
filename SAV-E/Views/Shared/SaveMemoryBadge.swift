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
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fillColor.opacity(fillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1.4)
                )

            icon
                .font(.system(size: size * 0.36, weight: .black))
                .foregroundColor(iconColor)

            Capsule()
                .fill(accentColor.opacity(0.82))
                .frame(width: size * 0.42, height: max(size * 0.08, 3))
                .padding(size * 0.12)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.saveCocoa.opacity(0.08), radius: 4, x: 0, y: 2)
        .accessibilityLabel(accessibilityLabel)
    }

    private var icon: some View {
        Group {
            switch state {
            case .clue:
                Image(systemName: "link")
            case .ready:
                Image(systemName: "seal")
            case .saved(let category):
                Image(systemName: category.stampIconName)
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

    private var fillOpacity: Double {
        switch state {
        case .clue:
            return 0.96
        case .ready:
            return 0.26
        case .saved:
            return 0.22
        }
    }

    private var iconColor: Color {
        switch state {
        case .clue:
            return .saveCocoa
        case .ready:
            return .saveInk
        case .saved:
            return .saveInk
        }
    }

    private var strokeColor: Color {
        switch state {
        case .clue:
            return Color.saveNotebookLine.opacity(0.45)
        case .ready:
            return Color.saveCocoa.opacity(0.28)
        case .saved(let category):
            return Color.saveStampColor(for: category).opacity(0.72)
        }
    }

    private var accentColor: Color {
        switch state {
        case .clue:
            return .saveCocoa
        case .ready:
            return .saveHoney
        case .saved(let category):
            return Color.saveStampColor(for: category)
        }
    }

    private var cornerRadius: CGFloat {
        max(size * 0.24, 10)
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

private extension PlaceCategory {
    var stampIconName: String {
        switch self {
        case .food: return "fork.knife"
        case .cafe: return "cup.and.saucer"
        case .bar: return "wineglass"
        case .attraction: return "star"
        case .stay: return "bed.double"
        case .shopping: return "bag"
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
