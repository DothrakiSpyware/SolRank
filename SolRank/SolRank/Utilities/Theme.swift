import SwiftUI

/// Convenience alias so the rest of the app can use `XPCategory` directly.
typealias XPCategory = Constants.XPCategory

extension Constants.XPCategory {
    /// Hex accent color per category (single source of truth).
    var colorHex: String {
        switch self {
        case .strength:   return "#E54345"
        case .endurance:  return "#F58C2E"
        case .wisdom:     return "#458CF2"
        case .discipline: return "#F8C738"
        case .willpower:  return "#9E66ED"
        case .vitality:   return "#4DC773"
        }
    }

    /// Accent color per category. Defined in code so the app renders without
    /// requiring asset-catalog color sets.
    var color: Color { Color(hex: colorHex) }
}

extension Color {
    /// Creates a color from a `#RRGGBB` hex string. Falls back to gold on bad input.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        guard cleaned.count == 6 else {
            self.init(.sRGB, red: 1, green: 0.84, blue: 0, opacity: 1)
            return
        }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

enum Theme {
    static let gold = Color(red: 0.98, green: 0.80, blue: 0.30)
    static let background = Color.black
    static let card = Color(white: 0.11)
    static let cardStroke = Color.white.opacity(0.08)

    static let goldGradient = LinearGradient(
        colors: [Color(red: 0.99, green: 0.85, blue: 0.4), Color(red: 0.96, green: 0.6, blue: 0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// A rounded dark card container used across the app.
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    func solCard() -> some View { modifier(CardModifier()) }
}
