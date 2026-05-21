import Foundation

/// A member's standing in a league. Stored at `leagueEntries/{leagueID}_{userID}`.
/// `rank` is assigned client-side after sorting and is not authoritative in Firestore.
struct LeagueEntry: Identifiable, Codable, Hashable {
    let id: String                       // "{leagueID}_{userID}"
    let leagueID: String
    let userID: String
    var username: String
    var totalPoints: Double
    var statBreakdown: [String: Double]  // statID → points earned from that stat
    var rank: Int

    init(
        leagueID: String,
        userID: String,
        username: String,
        totalPoints: Double = 0,
        statBreakdown: [String: Double] = [:],
        rank: Int = 0
    ) {
        self.id = "\(leagueID)_\(userID)"
        self.leagueID = leagueID
        self.userID = userID
        self.username = username
        self.totalPoints = totalPoints
        self.statBreakdown = statBreakdown
        self.rank = rank
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        leagueID = try c.decode(String.self, forKey: .leagueID)
        userID = try c.decode(String.self, forKey: .userID)
        username = try c.decodeIfPresent(String.self, forKey: .username) ?? "Member"
        totalPoints = try c.decodeIfPresent(Double.self, forKey: .totalPoints) ?? 0
        statBreakdown = try c.decodeIfPresent([String: Double].self, forKey: .statBreakdown) ?? [:]
        rank = try c.decodeIfPresent(Int.self, forKey: .rank) ?? 0
    }
}
