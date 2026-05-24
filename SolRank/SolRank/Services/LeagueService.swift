import Foundation
import FirebaseFirestore

enum LeagueError: LocalizedError {
    case insufficientPoints
    case notCancellable
    case leagueFull

    var errorDescription: String? {
        switch self {
        case .insufficientPoints: return "You don't have enough points for this entry wager."
        case .notCancellable: return "This league can no longer be cancelled."
        case .leagueFull: return "This league is full."
        }
    }
}

/// Reads and writes leagues, invites and leaderboard entries.
/// All point movements use atomic Firestore batch writes (spec §11).
@MainActor
final class LeagueService {
    private let db = Firestore.firestore()
    private let feedService: FeedService

    init(feedService: FeedService? = nil) {
        self.feedService = feedService ?? FeedService()
    }

    private var leagues: CollectionReference { db.collection(Constants.Firestore.leagues) }
    private var invites: CollectionReference { db.collection(Constants.Firestore.leagueInvites) }
    private var entries: CollectionReference { db.collection(Constants.Firestore.leagueEntries) }
    private var users: CollectionReference { db.collection(Constants.Firestore.users) }

    private let milestones: [Int] = [100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000]

    // MARK: - Creation

    func createLeague(_ league: League, invites inviteList: [LeagueInvite]) async throws {
        let batch = db.batch()

        try batch.setData(from: league, forDocument: leagues.document(league.id))

        // Creator's own leaderboard entry.
        let creatorEntry = LeagueEntry(
            leagueID: league.id,
            userID: league.creatorID,
            username: league.name(for: league.creatorID)
        )
        try batch.setData(from: creatorEntry, forDocument: entries.document(creatorEntry.id))

        for invite in inviteList {
            try batch.setData(from: invite, forDocument: invites.document(invite.id))
        }

        if league.entryWager > 0 {
            batch.updateData(
                ["pointsBalance": FieldValue.increment(Int64(-league.entryWager))],
                forDocument: users.document(league.creatorID)
            )
        }

        try await batch.commit()
    }

    // MARK: - Invites

    func acceptInvite(_ invite: LeagueInvite, user: AppUser) async throws {
        guard user.pointsBalance >= invite.entryWager else {
            throw LeagueError.insufficientPoints
        }

        let leagueRef = leagues.document(invite.leagueID)

        // Respect an optional participant cap.
        let snapshot = try await leagueRef.getDocument()
        if let league = try? snapshot.data(as: League.self), league.isFull {
            throw LeagueError.leagueFull
        }

        let batch = db.batch()
        let inviteRef = invites.document(invite.id)
        let userRef = users.document(user.id)
        let entryRef = entries.document("\(invite.leagueID)_\(invite.toUserID)")

        batch.updateData(["status": InviteStatus.accepted.rawValue], forDocument: inviteRef)
        batch.updateData([
            "memberIDs": FieldValue.arrayUnion([invite.toUserID]),
            FieldPath(["memberNames", invite.toUserID]): user.displayName
        ], forDocument: leagueRef)

        let entry = LeagueEntry(leagueID: invite.leagueID, userID: invite.toUserID, username: user.displayName)
        try batch.setData(from: entry, forDocument: entryRef)

        if invite.entryWager > 0 {
            batch.updateData(
                ["pointsBalance": FieldValue.increment(Int64(-invite.entryWager))],
                forDocument: userRef
            )
            batch.updateData(
                ["escrowedPoints": FieldValue.increment(Int64(invite.entryWager))],
                forDocument: leagueRef
            )
        }

        try await batch.commit()
    }

    func declineInvite(_ invite: LeagueInvite) async throws {
        try await invites.document(invite.id).updateData(["status": InviteStatus.declined.rawValue])
    }

    // MARK: - Progress

    func submitLeagueProgress(
        leagueID: String,
        userID: String,
        statID: String,
        value: Double,
        isBooleanStat: Bool
    ) async throws {
        guard value != 0 else { return }

        let leagueSnap = try await leagues.document(leagueID).getDocument()
        guard let league = try? leagueSnap.data(as: League.self),
              league.status == .active,
              let config = league.statConfigs.first(where: { $0.statID == statID })
        else { return }

        let pointsEarned = isBooleanStat ? config.pointsPerUnit : value * config.pointsPerUnit
        guard pointsEarned != 0 else { return }

        let entryRef = entries.document("\(leagueID)_\(userID)")
        let batch = db.batch()
        batch.updateData([
            "totalPoints": FieldValue.increment(pointsEarned),
            FieldPath(["statBreakdown", statID]): FieldValue.increment(pointsEarned)
        ], forDocument: entryRef)
        try await batch.commit()

        // Milestone feed event if the user crossed a round-number threshold.
        let entrySnap = try await entryRef.getDocument()
        guard let entry = try? entrySnap.data(as: LeagueEntry.self) else { return }
        if let milestone = crossedMilestone(previous: entry.totalPoints - pointsEarned, current: entry.totalPoints) {
            let event = FeedEvent(
                authorID: userID,
                authorUsername: entry.username,
                type: .leagueMilestone,
                message: "\(entry.username) hit \(milestone) points in \(league.name)",
                relatedID: leagueID
            )
            try? await feedService.postEvent(event)
        }
    }

    private func crossedMilestone(previous: Double, current: Double) -> Int? {
        milestones.last { Double($0) > previous && Double($0) <= current }
    }

    // MARK: - Resolution

    func resolveLeague(_ league: League) async throws {
        guard league.status == .active || league.status == .upcoming else { return }

        let leaderboard = try await fetchLeaderboard(leagueID: league.id)
        let batch = db.batch()
        let leagueRef = leagues.document(league.id)

        let payouts = computePayouts(league: league, leaderboard: leaderboard)
        for (userID, amount) in payouts where amount > 0 {
            batch.updateData(
                ["pointsBalance": FieldValue.increment(Int64(amount))],
                forDocument: users.document(userID)
            )
        }

        batch.updateData([
            "status": LeagueStatus.completed.rawValue,
            "escrowedPoints": 0
        ], forDocument: leagueRef)

        try await batch.commit()

        if let winner = leaderboard.first, winner.totalPoints > 0 {
            let event = FeedEvent(
                authorID: winner.userID,
                authorUsername: winner.username,
                type: .leagueMilestone,
                message: "\(winner.username) won \(league.name)! 🏆",
                relatedID: league.id
            )
            try? await feedService.postEvent(event)
        }
    }

    /// Returns userID → integer payout, exactly summing to escrowedPoints.
    private func computePayouts(league: League, leaderboard: [LeagueEntry]) -> [String: Int] {
        let escrow = league.escrowedPoints
        guard escrow > 0 else { return [:] }

        switch league.prizeStructure {
        case .noPoints:
            // Glory only — return every member's stake equally.
            return splitEqually(escrow, among: league.memberIDs)

        case .winnerTakesAll:
            guard let top = leaderboard.first else { return [:] }
            let winners = leaderboard.filter { $0.totalPoints == top.totalPoints }.map(\.userID)
            return splitEqually(escrow, among: winners)

        case .topThreeSplit:
            let n = min(3, leaderboard.count)
            guard n > 0 else { return [:] }
            let baseShares = Array([0.6, 0.3, 0.1].prefix(n))
            let total = baseShares.reduce(0, +)
            let weights = baseShares.map { $0 / total }   // normalize if < 3 members
            let recipients = (0..<n).map { leaderboard[$0].userID }
            return largestRemainder(escrow, weights: weights, recipients: recipients)
        }
    }

    private func splitEqually(_ total: Int, among ids: [String]) -> [String: Int] {
        guard !ids.isEmpty else { return [:] }
        let base = total / ids.count
        let remainder = total % ids.count
        var result: [String: Int] = [:]
        for (index, id) in ids.enumerated() {
            result[id, default: 0] += base + (index < remainder ? 1 : 0)
        }
        return result
    }

    /// Integer allocation by weights using the largest-remainder method (sum == total).
    private func largestRemainder(_ total: Int, weights: [Double], recipients: [String]) -> [String: Int] {
        guard !recipients.isEmpty else { return [:] }
        let raw = weights.map { Double(total) * $0 }
        var floors = raw.map { Int($0.rounded(.down)) }
        let allocated = floors.reduce(0, +)
        var remainder = total - allocated

        let fractionalOrder = raw.enumerated()
            .sorted { ($0.element - Double(floors[$0.offset])) > ($1.element - Double(floors[$1.offset])) }
            .map(\.offset)

        var i = 0
        while remainder > 0, i < fractionalOrder.count {
            floors[fractionalOrder[i]] += 1
            remainder -= 1
            i += 1
        }

        var result: [String: Int] = [:]
        for (index, id) in recipients.enumerated() {
            result[id, default: 0] += floors[index]
        }
        return result
    }

    func cancelLeague(_ league: League) async throws {
        guard league.status == .upcoming || league.status == .active else {
            throw LeagueError.notCancellable
        }

        let batch = db.batch()
        let leagueRef = leagues.document(league.id)

        if league.entryWager > 0 {
            for memberID in league.memberIDs {
                batch.updateData(
                    ["pointsBalance": FieldValue.increment(Int64(league.entryWager))],
                    forDocument: users.document(memberID)
                )
            }
        }
        batch.updateData([
            "status": LeagueStatus.cancelled.rawValue,
            "escrowedPoints": 0
        ], forDocument: leagueRef)

        try await batch.commit()
    }

    // MARK: - Reading

    func fetchActiveLeagues(for userID: String) async throws -> [League] {
        let snapshot = try await leagues
            .whereField("memberIDs", arrayContains: userID)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: League.self) }
            .filter { $0.status == .upcoming || $0.status == .active }
            .sorted { $0.startDate < $1.startDate }
    }

    func fetchPastLeagues(for userID: String) async throws -> [League] {
        let snapshot = try await leagues
            .whereField("memberIDs", arrayContains: userID)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: League.self) }
            .filter { $0.status == .completed || $0.status == .cancelled }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchPendingInvites(for userID: String) async throws -> [LeagueInvite] {
        let snapshot = try await invites
            .whereField("toUserID", isEqualTo: userID)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: LeagueInvite.self) }
            .filter { $0.status == .pending }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchLeaderboard(leagueID: String) async throws -> [LeagueEntry] {
        let snapshot = try await entries
            .whereField("leagueID", isEqualTo: leagueID)
            .getDocuments()
        return rank(snapshot.documents.compactMap { try? $0.data(as: LeagueEntry.self) })
    }

    /// Live leaderboard listener; sorts and ranks before each callback.
    func attachLeaderboardListener(
        leagueID: String,
        onChange: @escaping ([LeagueEntry]) -> Void
    ) -> ListenerRegistration {
        entries
            .whereField("leagueID", isEqualTo: leagueID)
            .addSnapshotListener { [weak self] snapshot, _ in
                // On error `snapshot` is nil — keep the caller's last data.
                guard let self, let snapshot else { return }
                let decoded = snapshot.documents.compactMap { try? $0.data(as: LeagueEntry.self) }
                onChange(self.rank(decoded))
            }
    }

    nonisolated private func rank(_ entries: [LeagueEntry]) -> [LeagueEntry] {
        var sorted = entries.sorted { $0.totalPoints > $1.totalPoints }
        for index in sorted.indices {
            sorted[index].rank = index + 1
        }
        return sorted
    }
}
