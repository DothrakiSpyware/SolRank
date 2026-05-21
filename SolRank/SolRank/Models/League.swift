import Foundation

enum LeagueStatus: String, Codable {
    case upcoming      // start date in future
    case active        // between start and end date (or no end date, started)
    case completed     // end date passed, prizes distributed
    case cancelled
}

enum PrizeStructure: String, Codable, CaseIterable {
    case winnerTakesAll     // 1st place gets all escrowed points
    case topThreeSplit      // 60% / 30% / 10%
    case noPoints           // no points awarded, glory only

    var displayName: String {
        switch self {
        case .winnerTakesAll: return "Winner takes all"
        case .topThreeSplit: return "Top 3 split (60/30/10)"
        case .noPoints: return "No points (glory only)"
        }
    }
}

/// A stat that scores in a league and how many points each unit is worth.
struct LeagueStatConfig: Identifiable, Codable, Hashable {
    let id: String
    let statID: String
    let statName: String
    let category: XPCategory
    let pointsPerUnit: Double      // e.g. 1 pushup = 1 pt, 1 page = 2 pts
    let isBooleanStat: Bool        // boolean stats award pointsPerUnit flat on log

    init(statID: String, statName: String, category: XPCategory, pointsPerUnit: Double, isBooleanStat: Bool) {
        self.id = statID
        self.statID = statID
        self.statName = statName
        self.category = category
        self.pointsPerUnit = pointsPerUnit
        self.isBooleanStat = isBooleanStat
    }
}

struct League: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var creatorID: String
    var memberIDs: [String]
    var memberNames: [String: String]        // denormalized userID → username
    var statConfigs: [LeagueStatConfig]
    var isPrivate: Bool                       // beta: always true (invite only)
    var startDate: Date
    var endDate: Date?                        // optional — can run indefinitely
    var status: LeagueStatus
    var prizeStructure: PrizeStructure
    var entryWager: Int                       // 0 if no wager
    var escrowedPoints: Int
    var maxParticipants: Int?                 // optional cap
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        creatorID: String,
        creatorName: String,
        statConfigs: [LeagueStatConfig],
        startDate: Date,
        endDate: Date?,
        prizeStructure: PrizeStructure,
        entryWager: Int,
        maxParticipants: Int?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.creatorID = creatorID
        self.memberIDs = [creatorID]
        self.memberNames = [creatorID: creatorName]
        self.statConfigs = statConfigs
        self.isPrivate = true
        self.startDate = startDate
        self.endDate = endDate
        self.status = startDate <= Date() ? .active : .upcoming
        self.prizeStructure = prizeStructure
        self.entryWager = entryWager
        self.escrowedPoints = entryWager   // creator escrows on creation
        self.maxParticipants = maxParticipants
        self.createdAt = Date()
    }

    // MARK: - Derived helpers

    var memberCount: Int { memberIDs.count }

    func name(for userID: String) -> String { memberNames[userID] ?? "Member" }

    var isFull: Bool {
        guard let cap = maxParticipants else { return false }
        return memberIDs.count >= cap
    }

    /// Whether the league's end date (if any) has passed.
    var isExpired: Bool {
        guard let endDate else { return false }
        return endDate <= Date()
    }

    var statusDisplay: String {
        switch status {
        case .upcoming: return "Upcoming"
        case .active: return "Active"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    /// Resilient decoding so documents missing newer/optional fields still load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "League"
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        creatorID = try c.decode(String.self, forKey: .creatorID)
        memberIDs = try c.decodeIfPresent([String].self, forKey: .memberIDs) ?? []
        memberNames = try c.decodeIfPresent([String: String].self, forKey: .memberNames) ?? [:]
        statConfigs = try c.decodeIfPresent([LeagueStatConfig].self, forKey: .statConfigs) ?? []
        isPrivate = try c.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? true
        startDate = try c.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
        endDate = try c.decodeIfPresent(Date.self, forKey: .endDate)
        status = try c.decodeIfPresent(LeagueStatus.self, forKey: .status) ?? .active
        prizeStructure = try c.decodeIfPresent(PrizeStructure.self, forKey: .prizeStructure) ?? .winnerTakesAll
        entryWager = try c.decodeIfPresent(Int.self, forKey: .entryWager) ?? 0
        escrowedPoints = try c.decodeIfPresent(Int.self, forKey: .escrowedPoints) ?? 0
        maxParticipants = try c.decodeIfPresent(Int.self, forKey: .maxParticipants)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}
