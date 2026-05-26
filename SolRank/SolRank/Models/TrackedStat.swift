import Foundation

/// A stat the user has chosen to track, with its running state.
/// Wraps a StatDefinition (preloaded or custom) plus per-user values.
struct TrackedStat: Identifiable, Codable, Hashable {
    var definition: StatDefinition
    var lifetimeTotal: Double
    var dailyValue: Double
    var dailyDate: Date        // the calendar day `dailyValue` applies to
    var currentStreak: Int
    var lastStreakDate: Date?  // last day a boolean stat was logged "yes"
    var dailyGoal: Double?     // optional daily target for progress bars
    var customIncrement: Double?  // user override of definition.defaultIncrement
    var showOnHome: Bool
    var celebrationEmoji: String   // emoji shown when a boolean stat is dormant-YES today
    var lastNoLogDate: Date?       // last day this boolean stat was logged "no"

    var id: String { definition.id }

    var increment: Double { customIncrement ?? definition.defaultIncrement }

    init(definition: StatDefinition, showOnHome: Bool = true) {
        self.definition = definition
        self.lifetimeTotal = 0
        self.dailyValue = 0
        self.dailyDate = Calendar.current.startOfDay(for: Date())
        self.currentStreak = 0
        self.lastStreakDate = nil
        self.dailyGoal = nil
        self.customIncrement = nil
        self.showOnHome = showOnHome
        self.celebrationEmoji = "🌟"
        self.lastNoLogDate = nil
    }

    /// True if a boolean stat has already been logged "yes" today.
    var isCompletedToday: Bool {
        guard definition.type == .boolean else { return false }
        return Calendar.current.isDateInToday(dailyDate) && dailyValue >= 1
    }

    /// True if a boolean stat was logged "no" today (dormant negative state).
    var isLoggedNoToday: Bool {
        guard definition.type == .boolean, let date = lastNoLogDate else { return false }
        return Calendar.current.isDateInToday(date)
    }

    /// True if a boolean check-in is locked for today (either yes or no).
    var isBooleanLockedToday: Bool {
        isCompletedToday || isLoggedNoToday
    }

    /// Rolls `dailyValue` over to zero if the stored day is not today.
    mutating func resetDailyIfNeeded(now: Date = Date()) {
        let today = Calendar.current.startOfDay(for: now)
        if !Calendar.current.isDate(dailyDate, inSameDayAs: today) {
            dailyValue = 0
            dailyDate = today
        }
    }

    // MARK: - Robust decoding (tolerate older docs missing new fields)

    private enum CodingKeys: String, CodingKey {
        case definition, lifetimeTotal, dailyValue, dailyDate, currentStreak,
             lastStreakDate, dailyGoal, customIncrement, showOnHome,
             celebrationEmoji, lastNoLogDate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        definition = try c.decode(StatDefinition.self, forKey: .definition)
        lifetimeTotal = try c.decodeIfPresent(Double.self, forKey: .lifetimeTotal) ?? 0
        dailyValue = try c.decodeIfPresent(Double.self, forKey: .dailyValue) ?? 0
        dailyDate = try c.decodeIfPresent(Date.self, forKey: .dailyDate)
            ?? Calendar.current.startOfDay(for: Date())
        currentStreak = try c.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        lastStreakDate = try c.decodeIfPresent(Date.self, forKey: .lastStreakDate)
        dailyGoal = try c.decodeIfPresent(Double.self, forKey: .dailyGoal)
        customIncrement = try c.decodeIfPresent(Double.self, forKey: .customIncrement)
        showOnHome = try c.decodeIfPresent(Bool.self, forKey: .showOnHome) ?? true
        celebrationEmoji = try c.decodeIfPresent(String.self, forKey: .celebrationEmoji) ?? "🌟"
        lastNoLogDate = try c.decodeIfPresent(Date.self, forKey: .lastNoLogDate)
    }
}
