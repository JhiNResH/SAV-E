import SwiftUI
import UIKit

extension Color {
    // MARK: - SAV-E Memo Scrapbook Theme
    static let saveCream = Color(light: "FFF5E7", dark: "15191F")
    static let saveMint = Color(hex: "C8EBCF")
    static let saveCocoa = Color(light: "3A2415", dark: "F7EFE5")
    static let saveHoney = Color(hex: "FFD66B")
    static let saveSky = Color(hex: "8FCAEA")
    static let saveInk = Color(light: "3A2415", dark: "FFF8ED")
    static let saveMutedText = Color(light: "7A5D45", dark: "CFC4B8")
    static let saveDisabled = Color(hex: "D7C0A6")
    static let savePaper = Color(light: "FFF0DC", dark: "1B2027")
    static let saveLedger = Color(light: "FFF5E7", dark: "15191F")
    static let saveSignal = Color(hex: "EE9C78")
    static let saveSuccess = Color(hex: "C8EBCF")
    static let saveCoral = Color(hex: "EE9C78")
    static let savePink = Color(hex: "F6C1CB")
    static let saveNotebookBackground = Color(light: "FFF5E7", dark: "101419")
    static let saveNotebookPage = Color(light: "FFF0DC", dark: "1B2027")
    static let saveNotebookSpine = Color(hex: "F6C181")
    static let saveNotebookLine = Color(light: "3A2415", dark: "6FFFFFFF")

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
        self.init(UIColor(hex: hex))
    }

    init(light lightHex: String, dark darkHex: String) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: darkHex)
                : UIColor(hex: lightHex)
        })
    }
}

private extension UIColor {
    convenience init(hex: String) {
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
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

extension View {
    func saveNotebookPage(cornerRadius: CGFloat = 18) -> some View {
        background(Color.saveNotebookPage)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.saveNotebookLine, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func saveOutlinedButton(
        fill: Color = .saveHoney,
        foreground: Color = .saveInk,
        cornerRadius: CGFloat = 14
    ) -> some View {
        font(.subheadline.weight(.black))
            .foregroundColor(foreground)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(fill)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.saveNotebookLine, lineWidth: 1.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct SaveDottedBackground: View {
    var body: some View {
        Color.saveNotebookBackground
            .overlay {
                Canvas { context, size in
                    let spacing: CGFloat = 18
                    for x in stride(from: CGFloat(8), through: size.width, by: spacing) {
                        for y in stride(from: CGFloat(8), through: size.height, by: spacing) {
                            let rect = CGRect(x: x, y: y, width: 2, height: 2)
                            context.fill(Path(ellipseIn: rect), with: .color(Color.saveNotebookLine.opacity(0.055)))
                        }
                    }
                }
                .allowsHitTesting(false)
            }
    }
}
