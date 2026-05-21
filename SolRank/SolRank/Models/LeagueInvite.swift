import Foundation

/// Invitation to join a league. Reuses the shared `InviteStatus` enum.
struct LeagueInvite: Identifiable, Codable {
    let id: String
    let leagueID: String
    let leagueName: String
    let fromUserID: String
    let fromUsername: String
    let toUserID: String
    let entryWager: Int
    let statNames: [String]
    let startDate: Date
    var status: InviteStatus
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        leagueID: String,
        leagueName: String,
        fromUserID: String,
        fromUsername: String,
        toUserID: String,
        entryWager: Int,
        statNames: [String],
        startDate: Date,
        status: InviteStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.leagueID = leagueID
        self.leagueName = leagueName
        self.fromUserID = fromUserID
        self.fromUsername = fromUsername
        self.toUserID = toUserID
        self.entryWager = entryWager
        self.statNames = statNames
        self.startDate = startDate
        self.status = status
        self.createdAt = createdAt
    }
}
