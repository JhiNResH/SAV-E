import SwiftUI

extension Color {
    // MARK: - Wanderly Light Theme
    static let wanderlyCream = Color(hex: "FFF8F0")
    static let wanderlyTerracotta = Color(hex: "C75B39")
    static let wanderlySage = Color(hex: "A8B5A0")
    static let wanderlyCharcoal = Color(hex: "2C2C2E")

    // MARK: - Wanderly Dark Theme
    static let wanderlyDarkBackground = Color(hex: "1C1C1E")
    static let wanderlyAmber = Color(hex: "E8A87C")

    // MARK: - Semantic Colors
    static let wanderlyBackground = Color("WanderlyBackground")
    static let wanderlyAccent = Color("WanderlyAccent")
    static let wanderlySecondary = Color("WanderlySecondary")
    static let wanderlyText = Color("WanderlyText")

    // MARK: - SAV-E Field Notebook Theme
    static let saveBlush = Color(hex: "FFF2E8")
    static let savePeach = Color(hex: "F1C889")
    static let saveCream = Color(hex: "FFF1DF")
    static let saveMint = Color(hex: "EAF1E7")
    static let saveBerry = Color(hex: "D85D4D")
    static let saveCocoa = Color(hex: "3D302A")
    static let saveRose = Color(hex: "8D5D4D")
    static let saveHoney = Color(hex: "FFD719")
    static let saveSky = Color(hex: "79D4DE")
    static let saveLavender = Color(hex: "EDE4D5")
    static let saveCard = Color.white.opacity(0.82)
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
        switch category {
        case .food: return .wanderlyTerracotta
        case .cafe: return Color(hex: "B07D62")
        case .bar: return Color(hex: "8B5E83")
        case .attraction: return Color(hex: "5B8FA8")
        case .stay: return .wanderlySage
        case .shopping: return Color(hex: "C4956A")
        }
    }

    static func saveStampColor(for category: PlaceCategory) -> Color {
        switch category {
        case .food: return .saveBerry
        case .cafe: return .saveHoney
        case .bar: return .saveCocoa
        case .attraction: return .saveSignal
        case .stay: return .saveMint
        case .shopping: return .savePeach
        }
    }

    static func saveStampForeground(for category: PlaceCategory) -> Color {
        switch category {
        case .cafe, .stay, .shopping: return .saveCocoa
        case .food, .bar, .attraction: return .white
        }
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

// MARK: - View Modifier for Wanderly Theme

struct WanderlyCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.wanderlyCream)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func wanderlyCard() -> some View {
        modifier(WanderlyCardStyle())
    }

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
