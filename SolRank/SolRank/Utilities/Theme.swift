import SwiftUI

extension Constants.XPCategory {
    /// Accent color per category. Defined in code so the app renders without
    /// requiring asset-catalog color sets.
    var color: Color {
        switch self {
        case .strength:   return Color(red: 0.90, green: 0.26, blue: 0.27)
        case .endurance:  return Color(red: 0.96, green: 0.55, blue: 0.18)
        case .wisdom:     return Color(red: 0.27, green: 0.55, blue: 0.95)
        case .discipline: return Color(red: 0.97, green: 0.78, blue: 0.22)
        case .willpower:  return Color(red: 0.62, green: 0.40, blue: 0.93)
        case .vitality:   return Color(red: 0.30, green: 0.78, blue: 0.45)
        }
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
