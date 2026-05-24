import SwiftUI

enum ChallengeStyle {
    /// Returns an accent color for a challenge based on its ID
    static func accent(for challenge: Challenge) -> Color {
        let colors: [Color] = [
            Theme.challengeBlue,
            Theme.challengePurple,
            Theme.challengeOrange,
            Theme.challengeGreen,
            Theme.challengeRed,
            Theme.challengePink
        ]
        
        let hash = abs(challenge.id.hashValue)
        return colors[hash % colors.count]
    }
}
