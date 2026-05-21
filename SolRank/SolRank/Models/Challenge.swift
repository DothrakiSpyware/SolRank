import Foundation

enum ChallengeGoalType: String, Codable {
    case firstToReach    // first participant to hit goalValue wins
    case mostByEndDate   // highest value when endDate is reached wins
}

enum ChallengeStatus: String, Codable {
    case pending     // created, waiting for all participants to accept
    case active      // all accepted, competition live
    case completed   // winner declared
    case cancelled   // creator cancelled before start
}

struct Challenge: Identifiable, Codable {
    let id: String
    var title: String
    var creatorID: String
    var participantIDs: [String]              // confirmed participants, creator included
    var participantNames: [String: String]    // userID → display name (denormalized for UI/feed)
    var statIDs: [String]                      // 1-3 stat IDs (spec: max 3)
    var statNames: [String]                    // display names, parallel to statIDs
    var goalType: ChallengeGoalType
    var goalValue: Double?                     // for "first to reach X" goal type
    var endDate: Date
    var status: ChallengeStatus
    var wagerAmount: Int                       // 0 if no wager
    var escrowedPoints: Int                    // total points held in escrow
    var participantProgress: [String: Double]  // userID → accumulated value
    var winnerID: String?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        creatorID: String,
        creatorName: String,
        statIDs: [String],
        statNames: [String],
        goalType: ChallengeGoalType,
        goalValue: Double? = nil,
        endDate: Date,
        wagerAmount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.creatorID = creatorID
        self.participantIDs = [creatorID]
        self.participantNames = [creatorID: creatorName]
        self.statIDs = statIDs
        self.statNames = statNames
        self.goalType = goalType
        self.goalValue = goalValue
        self.endDate = endDate
        self.status = .pending
        self.wagerAmount = wagerAmount
        self.escrowedPoints = wagerAmount   // creator escrows on creation
        self.participantProgress = [creatorID: 0]
        self.winnerID = nil
        self.createdAt = Date()
    }

    // MARK: - Derived helpers

    func progress(for userID: String) -> Double { participantProgress[userID] ?? 0 }

    func name(for userID: String) -> String { participantNames[userID] ?? "Challenger" }

    var totalProgress: Double { participantProgress.values.reduce(0, +) }

    /// Participants ranked by progress, highest first.
    var ranking: [(id: String, value: Double)] {
        participantIDs
            .map { ($0, participantProgress[$0] ?? 0) }
            .sorted { $0.1 > $1.1 }
    }

    var isExpired: Bool { endDate <= Date() }

    /// Resilient decoding so documents missing newer/optional fields still load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? "Challenge"
        creatorID = try c.decode(String.self, forKey: .creatorID)
        participantIDs = try c.decodeIfPresent([String].self, forKey: .participantIDs) ?? []
        participantNames = try c.decodeIfPresent([String: String].self, forKey: .participantNames) ?? [:]
        statIDs = try c.decodeIfPresent([String].self, forKey: .statIDs) ?? []
        statNames = try c.decodeIfPresent([String].self, forKey: .statNames) ?? []
        goalType = try c.decodeIfPresent(ChallengeGoalType.self, forKey: .goalType) ?? .mostByEndDate
        goalValue = try c.decodeIfPresent(Double.self, forKey: .goalValue)
        endDate = try c.decodeIfPresent(Date.self, forKey: .endDate) ?? Date()
        status = try c.decodeIfPresent(ChallengeStatus.self, forKey: .status) ?? .pending
        wagerAmount = try c.decodeIfPresent(Int.self, forKey: .wagerAmount) ?? 0
        escrowedPoints = try c.decodeIfPresent(Int.self, forKey: .escrowedPoints) ?? 0
        participantProgress = try c.decodeIfPresent([String: Double].self, forKey: .participantProgress) ?? [:]
        winnerID = try c.decodeIfPresent(String.self, forKey: .winnerID)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}
