import Foundation

/// A single logged entry for a stat.
struct StatEntry: Identifiable, Codable, Hashable {
    let id: String
    var statID: String
    var value: Double       // for boolean stats, 1 == yes
    var xpAwarded: Double
    var timestamp: Date
    var note: String?

    init(
        id: String = UUID().uuidString,
        statID: String,
        value: Double,
        xpAwarded: Double,
        timestamp: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.statID = statID
        self.value = value
        self.xpAwarded = xpAwarded
        self.timestamp = timestamp
        self.note = note
    }
}
