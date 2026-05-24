import SwiftUI

enum Theme {
    // MARK: - Colors
    static let background = Color.black
    static let cardBackground = Color(white: 0.1)
    static let cardStroke = Color(white: 0.2)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let silver = Color(white: 0.75)
    static let bronze = Color(red: 0.8, green: 0.5, blue: 0.2)
    static let card = Color(white: 0.12)
    static let goldGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.84, blue: 0.0),
            Color(red: 1.0, green: 0.65, blue: 0.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Challenge Colors
    static let challengeBlue = Color.blue
    static let challengePurple = Color.purple
    static let challengeOrange = Color.orange
    static let challengeGreen = Color.green
    static let challengeRed = Color.red
    static let challengePink = Color.pink
}

extension Color {
    /// Creates a color from a `#RRGGBB` hex string. Falls back to gold on bad input.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgbValue: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

