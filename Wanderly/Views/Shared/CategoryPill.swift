import SwiftUI

struct CategoryPill: View {
    let category: PlaceCategory
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.iconName)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(isSelected ? .saveInk : Color.saveStampForeground(for: category))
                .frame(width: 22, height: 22)
                .background(stampColor.opacity(isSelected ? 0.86 : 0.22))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(category.displayName)
                .font(.caption.weight(.black))
                .lineLimit(1)
        }
        .padding(.leading, 6)
        .padding(.trailing, 10)
        .padding(.vertical, 5)
        .background(isSelected ? stampColor.opacity(0.26) : Color.saveNotebookPage.opacity(0.82))
        .foregroundColor(isSelected ? .saveInk : .saveCocoa)
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(isSelected ? stampColor.opacity(0.62) : Color.saveCocoa.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: Color.saveCocoa.opacity(isSelected ? 0.10 : 0.04), radius: 8, y: 4)
    }

    private var stampColor: Color {
        Color.saveStampColor(for: category)
    }
}

#Preview {
    HStack {
        ForEach(PlaceCategory.allCases, id: \.self) { cat in
            CategoryPill(category: cat, isSelected: cat == .food)
        }
    }
    .padding()
}
