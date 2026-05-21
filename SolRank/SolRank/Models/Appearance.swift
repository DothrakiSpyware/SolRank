import Foundation

/// Pixel-art avatar configuration. Beta uses simple emoji-based placeholders
/// for sprites until the real pixel asset pack lands.
struct Appearance: Codable, Hashable {
    var head: String
    var shirt: String
    var pants: String
    var shoes: String

    static let `default` = Appearance(
        head: AppearanceOptions.heads[0],
        shirt: AppearanceOptions.shirts[0],
        pants: AppearanceOptions.pants[0],
        shoes: AppearanceOptions.shoes[0]
    )
}

/// Placeholder option sets. Real builds swap these emoji for pixel sprite asset names.
enum AppearanceOptions {
    static let heads = ["🧑", "👩", "🧔", "👱", "👵", "🧓", "👨‍🦰", "👩‍🦰", "👨‍🦱", "👩‍🦱", "🧑‍🦲", "👳"]
    static let shirts = ["🟥", "🟦", "🟩", "🟨", "🟪", "🟧", "⬛️", "⬜️"]
    static let pants = ["🟫", "🔵", "⚫️", "🟢", "🟣", "🟠"]
    static let shoes = ["👟", "🥾", "👢", "🥿", "👞", "🩴"]
}
