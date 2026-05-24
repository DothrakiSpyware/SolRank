import Foundation

/// Per-category XP accumulation. Drives hardlocked stat levels.
struct CategoryProgress: Codable, Hashable {
    var totalXP: Int = 0

    var level: Int { Leveling.level(forXP: totalXP) }
    var progressToNext: Double { Leveling.progressToNextLevel(xp: totalXP) }
    var xpRemaining: Int { Leveling.xpRemaining(xp: totalXP) }
}

/// A personal, non-comparable XP bar tied to custom stats.
struct CustomXPBar: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var totalXP: Int

    init(id: String = UUID().uuidString, name: String, totalXP: Int = 0) {
        self.id = id
        self.name = name
        self.totalXP = totalXP
    }

    var level: Int { Leveling.level(forXP: totalXP) }
    var progressToNext: Double { Leveling.progressToNextLevel(xp: totalXP) }
}

/// The user's RPG identity: appearance, XP per category, tracked stats.
struct Character: Identifiable, Codable {
    let id: String          // matches owner user id
    var ownerID: String
    var name: String
    var appearance: Appearance
    var categoryProgress: [String: CategoryProgress]   // keyed by XPCategory.rawValue
    var trackedStats: [TrackedStat]
    var customXPBars: [CustomXPBar]
    var recentEntries: [StatEntry]   // capped log history for daily/streak logic
    var createdAt: Date

    init(
        id: String,
        ownerID: String,
        name: String,
        appearance: Appearance = .default
    ) {
        self.id = id
        self.ownerID = ownerID
        self.name = name
        self.appearance = appearance
        var progress: [String: CategoryProgress] = [:]
        for category in XPCategory.allCases {
            progress[category.rawValue] = CategoryProgress()
        }
        self.categoryProgress = progress
        self.trackedStats = []
        self.customXPBars = []
        self.recentEntries = []
        self.createdAt = Date()
    }

    /// Overall character level = sum of all hardlocked category levels.
    var overallLevel: Int {
        XPCategory.allCases.reduce(0) { $0 + (categoryProgress[$1.rawValue]?.level ?? 1) }
    }

    func progress(for category: XPCategory) -> CategoryProgress {
        categoryProgress[category.rawValue] ?? CategoryProgress()
    }
}
