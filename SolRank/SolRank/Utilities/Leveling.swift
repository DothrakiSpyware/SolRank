import Foundation

/// RuneScape-inspired 1-99 leveling math.
/// XP required for each level follows the classic OSRS curve.
enum Leveling {
    static let maxLevel = Constants.maxXPLevel

    /// Cumulative XP required to *reach* a given level (level 1 = 0 XP).
    /// Index 0 is unused; thresholds[1] == 0, thresholds[2] == 83, ...
    static let thresholds: [Int] = {
        var points = 0.0
        var table: [Int] = [0, 0] // index 0 unused, level 1 = 0
        for level in 1..<maxLevel {
            points += floor(Double(level) + 300.0 * pow(2.0, Double(level) / 7.0))
            table.append(Int(floor(points / 4.0)))
        }
        return table
    }()

    /// The level a given amount of total XP corresponds to (clamped 1...maxLevel).
    static func level(forXP xp: Int) -> Int {
        guard xp > 0 else { return 1 }
        var result = 1
        for level in 1...maxLevel where thresholds[level] <= xp {
            result = level
        }
        return result
    }

    /// Total XP required to reach the start of `level`.
    static func xpToReach(level: Int) -> Int {
        let clamped = min(max(level, 1), maxLevel)
        return thresholds[clamped]
    }

    /// Progress (0...1) through the current level toward the next.
    static func progressToNextLevel(xp: Int) -> Double {
        let current = level(forXP: xp)
        guard current < maxLevel else { return 1.0 }
        let floorXP = thresholds[current]
        let ceilXP = thresholds[current + 1]
        let span = ceilXP - floorXP
        guard span > 0 else { return 1.0 }
        return Double(xp - floorXP) / Double(span)
    }

    /// XP remaining to reach the next level (0 at max level).
    static func xpRemaining(xp: Int) -> Int {
        let current = level(forXP: xp)
        guard current < maxLevel else { return 0 }
        return thresholds[current + 1] - xp
    }
}
