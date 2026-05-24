import Foundation
import SwiftUI

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

    var color: Color {
        switch self {
        case .strength: return .red
        case .endurance: return .orange
        case .wisdom: return .blue
        case .discipline: return .yellow
        case .willpower: return .purple
        case .vitality: return .green
        }
    }
}

enum Constants {
    enum Firestore {
        static let users = "users"
        static let characters = "characters"
        static let stats = "stats"
        static let challenges = "challenges"
        static let challengeInvites = "challengeInvites"
        static let leagues = "leagues"
        static let leagueInvites = "leagueInvites"
        static let leagueEntries = "leagueEntries"
        static let feedEvents = "feedEvents"
    }

    static let startingPointsBalance = 100
    static let maxXPLevel = 99
}
