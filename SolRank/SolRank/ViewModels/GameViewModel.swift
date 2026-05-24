import Foundation
import SwiftUI

/// Owns the live Character state and the logging loop — the core RPG engine.
/// Logging a stat updates daily/lifetime values, awards XP to the right bar,
/// detects level-ups, records an entry, and persists (best effort).
@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var character: Character?
    @Published private(set) var isLoading = true
    @Published var levelUpEvent: LevelUpEvent?   // drives the celebration overlay

    private let service: GameService
    private let feedService: FeedService
    private let challengeService: ChallengeService
    private let leagueService: LeagueService
    private let recentEntryCap = 100
    private let streakMilestones = [7, 30, 100]

    /// Cached active challenges the user is in, used to route logged values into
    /// challenge progress. Refreshed on load; only stat membership is read from it.
    private var activeChallenges: [Challenge] = []

    /// Cached active leagues the user is in, used to route logged values into
    /// league scoring. Refreshed on load.
    private var activeLeagues: [League] = []

    init(
        service: GameService = GameService(),
        feedService: FeedService = FeedService(),
        challengeService: ChallengeService = ChallengeService(),
        leagueService: LeagueService = LeagueService()
    ) {
        self.service = service
        self.feedService = feedService
        self.challengeService = challengeService
        self.leagueService = leagueService
    }

    var needsOnboarding: Bool { !isLoading && character == nil }

    // MARK: - Loading

    func load(userID: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            if var loaded = try await service.loadCharacter(userID: userID) {
                rollDailyValues(&loaded)
                character = loaded
            } else {
                character = nil
            }
        } catch {
            // Offline / first run: leave character nil so onboarding can proceed.
            character = nil
        }
        await refreshChallenges(for: userID)
        await refreshLeagues(for: userID)
    }

    /// Reloads the user's active challenges so logging can feed their progress.
    func refreshChallenges(for userID: String) async {
        activeChallenges = (try? await challengeService.fetchActiveChallenges(for: userID)) ?? []
    }

    /// Reloads the user's active leagues so logging can feed their scoring.
    func refreshLeagues(for userID: String) async {
        activeLeagues = (try? await leagueService.fetchActiveLeagues(for: userID)) ?? []
    }

    /// Routes a logged value into any active challenge that tracks this stat.
    private func submitChallengeProgress(statID: String, value: Double) {
        guard let userID = character?.ownerID, value > 0 else { return }
        let relevant = activeChallenges.filter {
            $0.status == .active && $0.participantIDs.contains(userID) && $0.statIDs.contains(statID)
        }
        for challenge in relevant {
            Task { try? await challengeService.submitProgress(challengeID: challenge.id, userID: userID, value: value) }
        }
    }

    /// Routes a logged value into any active league that scores this stat.
    private func submitLeagueProgress(statID: String, value: Double, isBooleanStat: Bool) {
        guard let userID = character?.ownerID, value > 0 else { return }
        let relevant = activeLeagues.filter {
            $0.status == .active && $0.memberIDs.contains(userID) && $0.statConfigs.contains { $0.statID == statID }
        }
        for league in relevant {
            Task {
                try? await leagueService.submitLeagueProgress(
                    leagueID: league.id,
                    userID: userID,
                    statID: statID,
                    value: value,
                    isBooleanStat: isBooleanStat
                )
            }
        }
    }

    // MARK: - Character creation (onboarding)

    func createCharacter(userID: String, name: String, appearance: Appearance, selectedStatIDs: [String]) async {
        var new = Character(id: userID, ownerID: userID, name: name, appearance: appearance)
        new.trackedStats = selectedStatIDs.compactMap { id in
            PreloadedStats.stat(id: id).map { TrackedStat(definition: $0) }
        }
        character = new
        await persist()
    }

    // MARK: - Logging

    /// Logs an increment for a numeric stat. Returns the XP awarded.
    @discardableResult
    func logNumeric(statID: String, amount: Double) -> Double {
        guard var char = character,
              let index = char.trackedStats.firstIndex(where: { $0.id == statID }),
              char.trackedStats[index].definition.type == .numeric,
              amount != 0
        else { return 0 }

        char.trackedStats[index].resetDailyIfNeeded()
        char.trackedStats[index].dailyValue += amount
        char.trackedStats[index].lifetimeTotal += amount

        let definition = char.trackedStats[index].definition
        let xp = amount * definition.xpPerUnit
        applyXP(&char, definition: definition, xp: xp)
        appendEntry(&char, statID: statID, value: amount, xp: xp)

        let authorID = char.ownerID
        let authorName = char.name
        commit(char)

        emitFeed(
            authorID: authorID,
            authorUsername: authorName,
            type: .statLogged,
            message: "logged \(formatLog(amount)) \(definition.name.lowercased())",
            xp: Int(xp.rounded()),
            category: definition.category
        )
        submitChallengeProgress(statID: statID, value: amount)
        submitLeagueProgress(statID: statID, value: amount, isBooleanStat: false)
        return xp
    }

    /// Toggles a boolean stat for today. Logging "yes" awards XP and extends the streak.
    func setBoolean(statID: String, completed: Bool) {
        guard var char = character,
              let index = char.trackedStats.firstIndex(where: { $0.id == statID }),
              char.trackedStats[index].definition.type == .boolean
        else { return }

        char.trackedStats[index].resetDailyIfNeeded()
        let alreadyDone = char.trackedStats[index].dailyValue >= 1
        guard alreadyDone != completed else { return }

        let definition = char.trackedStats[index].definition
        let xpPerCompletion = definition.xpPerUnit

        if completed {
            char.trackedStats[index].dailyValue = 1
            char.trackedStats[index].lifetimeTotal += 1
            updateStreak(&char.trackedStats[index], loggedYes: true)
            applyXP(&char, definition: definition, xp: xpPerCompletion)
            appendEntry(&char, statID: statID, value: 1, xp: xpPerCompletion)

            let authorID = char.ownerID
            let authorName = char.name
            let streak = char.trackedStats[index].currentStreak
            commit(char)

            emitFeed(
                authorID: authorID,
                authorUsername: authorName,
                type: .statLogged,
                message: "completed \(definition.name.lowercased())",
                xp: Int(xpPerCompletion.rounded()),
                category: definition.category
            )
            if streakMilestones.contains(streak) {
                let label = definition.category?.rawValue ?? definition.name
                emitFeed(
                    authorID: authorID,
                    authorUsername: authorName,
                    type: .streakMilestone,
                    message: "is on a \(streak)-day \(label) streak 🔥",
                    xp: nil,
                    category: definition.category
                )
            }
            submitChallengeProgress(statID: statID, value: 1)
            submitLeagueProgress(statID: statID, value: 1, isBooleanStat: true)
        } else {
            // Undo today's completion.
            char.trackedStats[index].dailyValue = 0
            char.trackedStats[index].lifetimeTotal = max(0, char.trackedStats[index].lifetimeTotal - 1)
            updateStreak(&char.trackedStats[index], loggedYes: false)
            applyXP(&char, definition: definition, xp: -xpPerCompletion)
            char.recentEntries.removeAll { $0.statID == statID && Calendar.current.isDateInToday($0.timestamp) }
            commit(char)
        }
    }

    // MARK: - Stat management

    func addTrackedStat(_ definition: StatDefinition) {
        guard var char = character,
              !char.trackedStats.contains(where: { $0.id == definition.id })
        else { return }
        char.trackedStats.append(TrackedStat(definition: definition))
        if let bar = definition.customXPBarID,
           !char.customXPBars.contains(where: { $0.id == bar }) {
            // Custom XP bar referenced but missing — create a placeholder.
            char.customXPBars.append(CustomXPBar(id: bar, name: definition.name))
        }
        commit(char)
    }

    func removeTrackedStat(statID: String) {
        guard var char = character else { return }
        char.trackedStats.removeAll { $0.id == statID }
        commit(char)
    }

    func setShowOnHome(statID: String, _ show: Bool) {
        guard var char = character,
              let index = char.trackedStats.firstIndex(where: { $0.id == statID })
        else { return }
        char.trackedStats[index].showOnHome = show
        commit(char)
    }

    // MARK: - Derived

    var homeStats: [TrackedStat] {
        character?.trackedStats.filter { $0.showOnHome } ?? []
    }

    // MARK: - Internal helpers

    private func applyXP(_ char: inout Character, definition: StatDefinition, xp: Double) {
        guard xp != 0 else { return }

        if let category = definition.category {   // hardlocked stat → category XP
            let key = category.rawValue
            var progress = char.categoryProgress[key] ?? CategoryProgress()
            let before = progress.level
            progress.totalXP = max(0, progress.totalXP + Int(xp.rounded()))
            char.categoryProgress[key] = progress
            if progress.level > before {
                levelUpEvent = LevelUpEvent(title: category.rawValue, icon: category.icon, newLevel: progress.level)
                emitFeed(
                    authorID: char.ownerID,
                    authorUsername: char.name,
                    type: .levelUp,
                    message: "reached \(category.rawValue) Level \(progress.level) \(category.icon)",
                    xp: nil,
                    category: category
                )
            }
        } else if let barID = definition.customXPBarID,
                  let barIndex = char.customXPBars.firstIndex(where: { $0.id == barID }) {
            let before = char.customXPBars[barIndex].level
            char.customXPBars[barIndex].totalXP = max(0, char.customXPBars[barIndex].totalXP + Int(xp.rounded()))
            if char.customXPBars[barIndex].level > before {
                let bar = char.customXPBars[barIndex]
                levelUpEvent = LevelUpEvent(title: bar.name, icon: "⭐️", newLevel: bar.level)
                emitFeed(
                    authorID: char.ownerID,
                    authorUsername: char.name,
                    type: .levelUp,
                    message: "reached \(bar.name) Level \(bar.level) ⭐️",
                    xp: nil,
                    category: nil
                )
            }
        }
        // Custom stat with no XP bar → no XP, by design.
    }

    private func updateStreak(_ stat: inout TrackedStat, loggedYes: Bool) {
        let calendar = Calendar.current
        if loggedYes {
            if let last = stat.lastStreakDate, calendar.isDateInYesterday(last) {
                stat.currentStreak += 1
            } else if let last = stat.lastStreakDate, calendar.isDateInToday(last) {
                // already counted today
            } else {
                stat.currentStreak = 1
            }
            stat.lastStreakDate = calendar.startOfDay(for: Date())
        } else {
            stat.currentStreak = max(0, stat.currentStreak - 1)
            stat.lastStreakDate = nil
        }
    }

    private func appendEntry(_ char: inout Character, statID: String, value: Double, xp: Double) {
        char.recentEntries.insert(
            StatEntry(statID: statID, value: value, xpAwarded: xp),
            at: 0
        )
        if char.recentEntries.count > recentEntryCap {
            char.recentEntries.removeLast(char.recentEntries.count - recentEntryCap)
        }
    }

    private func rollDailyValues(_ char: inout Character) {
        for index in char.trackedStats.indices {
            char.trackedStats[index].resetDailyIfNeeded()
        }
    }

    private func commit(_ char: Character) {
        character = char
        Task { await persist() }
    }

    private func persist() async {
        guard let char = character else { return }
        try? await service.saveCharacter(char)
    }

    // MARK: - Feed emission

    private func emitFeed(
        authorID: String,
        authorUsername: String,
        type: FeedEventType,
        message: String,
        xp: Int?,
        category: XPCategory?
    ) {
        let event = FeedEvent(
            authorID: authorID,
            authorUsername: authorUsername,
            type: type,
            message: message,
            xpGained: xp,
            statCategory: category
        )
        Task { try? await feedService.postEvent(event) }
    }

    private func formatLog(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

/// Payload for the full-screen level-up celebration.
struct LevelUpEvent: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String
    let newLevel: Int
}
