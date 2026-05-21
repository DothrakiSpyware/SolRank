import Foundation

/// How a stat is tracked.
enum StatType: String, Codable, CaseIterable {
    case numeric   // user logs a number that accumulates (e.g. 50 pushups)
    case boolean   // user logs yes/no for today, builds a streak

    var displayName: String {
        switch self {
        case .numeric: return "Numeric"
        case .boolean: return "Yes / No"
        }
    }
}

/// The definition (template) of a stat — what it is, how it scores XP.
/// Preloaded stats and custom stats both use this shape.
struct StatDefinition: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var category: Constants.XPCategory?   // nil for custom stats (they don't feed hardlocked XP)
    var type: StatType
    var unit: String?                     // e.g. "reps", "miles" — nil for boolean
    var xpPerUnit: Double                 // XP awarded per unit (numeric) or per completion (boolean)
    var defaultIncrement: Double          // default quick-log increment per tap
    var isCustom: Bool
    var customXPBarID: String?            // links a custom stat to a custom XP bar, if any

    init(
        id: String = UUID().uuidString,
        name: String,
        category: Constants.XPCategory?,
        type: StatType,
        unit: String? = nil,
        xpPerUnit: Double,
        defaultIncrement: Double = 1,
        isCustom: Bool = false,
        customXPBarID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.type = type
        self.unit = unit
        self.xpPerUnit = xpPerUnit
        self.defaultIncrement = defaultIncrement
        self.isCustom = isCustom
        self.customXPBarID = customXPBarID
    }
}
