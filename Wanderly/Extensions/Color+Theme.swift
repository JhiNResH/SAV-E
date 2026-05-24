import SwiftUI

extension Color {
    // MARK: - SAV-E Field Notebook Theme
    static let saveCream = Color(hex: "FFF1DF")
    static let saveMint = Color(hex: "EAF1E7")
    static let saveCocoa = Color(hex: "3D302A")
    static let saveHoney = Color(hex: "FFD719")
    static let saveSky = Color(hex: "79D4DE")
    static let saveInk = Color(hex: "241D21")
    static let savePaper = Color(hex: "FFFDF7")
    static let saveLedger = Color(hex: "EFE7D6")
    static let saveSignal = Color(hex: "6E7F67")
    static let saveSuccess = Color(hex: "6F946D")
    static let saveNotebookBackground = Color(hex: "F4B51B")
    static let saveNotebookPage = Color(hex: "FFF1DF")
    static let saveNotebookSpine = Color(hex: "FFD719")
    static let saveNotebookLine = Color(hex: "3D302A")

    // MARK: - Category Colors
    static func categoryColor(for category: PlaceCategory) -> Color {
        saveStampColor(for: category)
    }

    static func saveStampColor(for category: PlaceCategory) -> Color {
        .saveHoney
    }

    static func saveStampForeground(for category: PlaceCategory) -> Color {
        .saveInk
    }

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func saveNotebookPage(cornerRadius: CGFloat = 18) -> some View {
        background(Color.saveNotebookPage)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.saveNotebookLine.opacity(0.88), lineWidth: 1.2)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.saveInk.opacity(0.16), radius: 0, x: 3, y: 3)
    }
}

struct SaveDottedBackground: View {
    var body: some View {
        Color.saveNotebookBackground
            .overlay {
                Canvas { context, size in
                    let spacing: CGFloat = 14
                    for x in stride(from: CGFloat(7), through: size.width, by: spacing) {
                        for y in stride(from: CGFloat(7), through: size.height, by: spacing) {
                            let rect = CGRect(x: x, y: y, width: 2.2, height: 2.2)
                            context.fill(Path(ellipseIn: rect), with: .color(Color.saveInk.opacity(0.28)))
                        }
                    }
                }
                .allowsHitTesting(false)
            }
    }
}
