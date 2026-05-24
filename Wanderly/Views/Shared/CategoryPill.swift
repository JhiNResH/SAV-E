import SwiftUI

struct CategoryPill: View {
    let category: PlaceCategory
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.iconName)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.saveInk)
                .frame(width: 22, height: 22)
                .background(isSelected ? Color.saveHoney : Color.saveNotebookLine.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(category.displayName)
                .font(.caption.weight(.black))
                .lineLimit(1)
        }
        .padding(.leading, 6)
        .padding(.trailing, 10)
        .padding(.vertical, 5)
        .background(isSelected ? Color.saveHoney : Color.saveNotebookPage)
        .foregroundColor(.saveInk)
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.saveNotebookLine, lineWidth: isSelected ? 2 : 1.4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: Color.saveInk.opacity(isSelected ? 0.18 : 0.10), radius: 0, x: 3, y: 3)
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
