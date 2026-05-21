import Foundation

enum Constants {
    enum XPCategory: String, CaseIterable, Codable {
        case strength = "Strength"
        case endurance = "Endurance"
        case wisdom = "Wisdom"
        case discipline = "Discipline"
        case willpower = "Willpower"
        case vitality = "Vitality"

        var icon: String {
            switch self {
            case .strength: return "💪"
            case .endurance: return "🏃"
            case .wisdom: return "📖"
            case .discipline: return "🔥"
            case .willpower: return "🧠"
            case .vitality: return "❤️"
            }
        }

        var accentColor: String {
            switch self {
            case .strength: return "StatRed"
            case .endurance: return "StatOrange"
            case .wisdom: return "StatBlue"
            case .discipline: return "StatYellow"
            case .willpower: return "StatPurple"
            case .vitality: return "StatGreen"
            }
        }
    }

    enum Firestore {
        static let users = "users"
        static let characters = "characters"
        static let stats = "stats"
        static let challenges = "challenges"
        static let challengeInvites = "challengeInvites"
        static let leagues = "leagues"
        static let feedEvents = "feedEvents"
    }

    static let startingPointsBalance = 100
    static let maxXPLevel = 99
}
