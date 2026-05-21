import Foundation

enum InviteStatus: String, Codable {
    case pending
    case accepted
    case declined
}

struct ChallengeInvite: Identifiable, Codable {
    let id: String
    let challengeID: String
    let challengeTitle: String
    let fromUserID: String
    let fromUsername: String
    let toUserID: String
    let wagerAmount: Int
    let statNames: [String]
    let endDate: Date
    var status: InviteStatus
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        challengeID: String,
        challengeTitle: String,
        fromUserID: String,
        fromUsername: String,
        toUserID: String,
        wagerAmount: Int,
        statNames: [String],
        endDate: Date,
        status: InviteStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.challengeID = challengeID
        self.challengeTitle = challengeTitle
        self.fromUserID = fromUserID
        self.fromUsername = fromUsername
        self.toUserID = toUserID
        self.wagerAmount = wagerAmount
        self.statNames = statNames
        self.endDate = endDate
        self.status = status
        self.createdAt = createdAt
    }
}
