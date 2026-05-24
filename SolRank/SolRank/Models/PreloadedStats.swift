import Foundation

/// The hardlocked, app-defined stat catalog from the spec.
/// XP-per-unit values are fixed and not user-editable.
enum PreloadedStats {
    static let all: [StatDefinition] = strength + endurance + wisdom + discipline + willpower + vitality

    static func grouped() -> [(category: XPCategory, stats: [StatDefinition])] {
        XPCategory.allCases.map { category in
            (category, all.filter { $0.category == category })
        }
    }

    static func stat(id: String) -> StatDefinition? {
        all.first { $0.id == id }
    }

    // MARK: - Catalog (stable IDs so user selections persist across launches)

    static let strength: [StatDefinition] = [
        .init(id: "pushups", name: "Pushups", category: .strength, type: .numeric, unit: "reps", xpPerUnit: 1, defaultIncrement: 10),
        .init(id: "situps", name: "Situps", category: .strength, type: .numeric, unit: "reps", xpPerUnit: 1, defaultIncrement: 10),
        .init(id: "strength_train", name: "Strength trained today", category: .strength, type: .boolean, xpPerUnit: 50)
    ]

    static let endurance: [StatDefinition] = [
        .init(id: "miles_run", name: "Miles Run", category: .endurance, type: .numeric, unit: "miles", xpPerUnit: 50, defaultIncrement: 1),
        .init(id: "miles_walked", name: "Miles Walked", category: .endurance, type: .numeric, unit: "miles", xpPerUnit: 20, defaultIncrement: 1),
        .init(id: "steps", name: "Steps", category: .endurance, type: .numeric, unit: "steps", xpPerUnit: 0.01, defaultIncrement: 1000),
        .init(id: "cardio", name: "Did cardio today", category: .endurance, type: .boolean, xpPerUnit: 50)
    ]

    static let wisdom: [StatDefinition] = [
        .init(id: "pages_read", name: "Pages Read", category: .wisdom, type: .numeric, unit: "pages", xpPerUnit: 5, defaultIncrement: 10),
        .init(id: "studied", name: "Studied / learned today", category: .wisdom, type: .boolean, xpPerUnit: 50),
        .init(id: "edu_minutes", name: "Minutes of educational content", category: .wisdom, type: .numeric, unit: "min", xpPerUnit: 2, defaultIncrement: 15)
    ]

    static let discipline: [StatDefinition] = [
        .init(id: "daily_streak", name: "Maintained daily streak", category: .discipline, type: .boolean, xpPerUnit: 25),
        .init(id: "challenge_done", name: "Completed a commitment", category: .discipline, type: .numeric, unit: "completed", xpPerUnit: 100, defaultIncrement: 1)
    ]

    static let willpower: [StatDefinition] = [
        .init(id: "no_smoking", name: "No smoking today", category: .willpower, type: .boolean, xpPerUnit: 40),
        .init(id: "bed_on_time", name: "In bed by goal time", category: .willpower, type: .boolean, xpPerUnit: 30),
        .init(id: "no_coffee", name: "No coffee today", category: .willpower, type: .boolean, xpPerUnit: 30),
        .init(id: "screen_time", name: "Met screen time goal", category: .willpower, type: .boolean, xpPerUnit: 30)
    ]

    static let vitality: [StatDefinition] = [
        .init(id: "ate_healthy", name: "Ate healthy today", category: .vitality, type: .boolean, xpPerUnit: 30),
        .init(id: "hydrated", name: "Drank enough water", category: .vitality, type: .boolean, xpPerUnit: 30)
    ]
}
