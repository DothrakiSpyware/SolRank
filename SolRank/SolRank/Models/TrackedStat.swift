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
    }

    /// True if a boolean stat has already been logged "yes" today.
    var isCompletedToday: Bool {
        guard definition.type == .boolean else { return false }
        return Calendar.current.isDateInToday(dailyDate) && dailyValue >= 1
    }

    /// Rolls `dailyValue` over to zero if the stored day is not today.
    mutating func resetDailyIfNeeded(now: Date = Date()) {
        let today = Calendar.current.startOfDay(for: now)
        if !Calendar.current.isDate(dailyDate, inSameDayAs: today) {
            dailyValue = 0
            dailyDate = today
        }
    }
}
