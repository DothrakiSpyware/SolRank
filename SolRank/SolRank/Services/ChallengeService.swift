import Foundation
import FirebaseFirestore

enum ChallengeError: LocalizedError {
    case insufficientPoints
    case notCreator
    case notCancellable

    var errorDescription: String? {
        switch self {
        case .insufficientPoints: return "You don't have enough points for this wager."
        case .notCreator: return "Only the creator can do that."
        case .notCancellable: return "This challenge can no longer be cancelled."
        }
    }
}

/// Reads and writes challenges + invites. All point movements use Firestore
/// batch writes so escrow transfers are atomic (spec §11).
@MainActor
final class ChallengeService {
    private let db = Firestore.firestore()
    private let feedService: FeedService

    init(feedService: FeedService = FeedService()) {
        self.feedService = feedService
    }

    private var challenges: CollectionReference { db.collection(Constants.Firestore.challenges) }
    private var invites: CollectionReference { db.collection(Constants.Firestore.challengeInvites) }
    private var users: CollectionReference { db.collection(Constants.Firestore.users) }

    // MARK: - Creation

    /// Writes the challenge and its invites. The creator's wager (if any) is
    /// escrowed atomically here; invitees are charged when they accept.
    func createChallenge(_ challenge: Challenge, invites inviteList: [ChallengeInvite]) async throws {
        let batch = db.batch()

        let challengeRef = challenges.document(challenge.id)
        try batch.setData(from: challenge, forDocument: challengeRef)

        for invite in inviteList {
            try batch.setData(from: invite, forDocument: invites.document(invite.id))
        }

        if challenge.wagerAmount > 0 {
            // Creator escrows their stake immediately.
            batch.updateData(
                ["pointsBalance": FieldValue.increment(Int64(-challenge.wagerAmount))],
                forDocument: users.document(challenge.creatorID)
            )
        }

        try await batch.commit()
    }

    // MARK: - Invites

    func acceptInvite(_ invite: ChallengeInvite, user: AppUser) async throws {
        guard user.pointsBalance >= invite.wagerAmount else {
            throw ChallengeError.insufficientPoints
        }

        let batch = db.batch()
        let inviteRef = invites.document(invite.id)
        let userRef = users.document(user.id)
        let challengeRef = challenges.document(invite.challengeID)

        batch.updateData(["status": InviteStatus.accepted.rawValue], forDocument: inviteRef)
        batch.updateData([
            "participantIDs": FieldValue.arrayUnion([invite.toUserID]),
            FieldPath(["participantNames", invite.toUserID]): user.displayName,
            FieldPath(["participantProgress", invite.toUserID]): 0
        ], forDocument: challengeRef)

        if invite.wagerAmount > 0 {
            batch.updateData(
                ["pointsBalance": FieldValue.increment(Int64(-invite.wagerAmount))],
                forDocument: userRef
            )
            batch.updateData(
                ["escrowedPoints": FieldValue.increment(Int64(invite.wagerAmount))],
                forDocument: challengeRef
            )
        }

        try await batch.commit()
        try await activateIfAllAccepted(invite: invite)
    }

    func declineInvite(_ invite: ChallengeInvite) async throws {
        try await invites.document(invite.id).updateData(["status": InviteStatus.declined.rawValue])
    }

    /// Marks the challenge active once no invites remain pending, then posts a feed event.
    private func activateIfAllAccepted(invite: ChallengeInvite) async throws {
        let allInvites = try await invites
            .whereField("challengeID", isEqualTo: invite.challengeID)
            .getDocuments()
        let stillPending = allInvites.documents
            .compactMap { try? $0.data(as: ChallengeInvite.self) }
            .contains { $0.status == .pending }
        guard !stillPending else { return }

        let ref = challenges.document(invite.challengeID)
        let snapshot = try await ref.getDocument()
        guard let challenge = try? snapshot.data(as: Challenge.self), challenge.status == .pending else { return }

        try await ref.updateData(["status": ChallengeStatus.active.rawValue])

        let event = FeedEvent(
            authorID: challenge.creatorID,
            authorUsername: invite.fromUsername,
            type: .challengeUpdate,
            message: "\(challenge.title) is live! ⚔️",
            relatedID: challenge.id
        )
        try? await feedService.postEvent(event)
    }

    // MARK: - Progress

    func submitProgress(challengeID: String, userID: String, value: Double) async throws {
        guard value != 0 else { return }
        let ref = challenges.document(challengeID)
        try await ref.updateData([
            FieldPath(["participantProgress", userID]): FieldValue.increment(value)
        ])

        // Resolve immediately if this is a race-to-goal challenge and the goal is hit.
        let snapshot = try await ref.getDocument()
        guard let challenge = try? snapshot.data(as: Challenge.self),
              challenge.status == .active,
              challenge.goalType == .firstToReach,
              let goal = challenge.goalValue
        else { return }

        if challenge.participantProgress.values.contains(where: { $0 >= goal }) {
            try await resolveChallenge(challenge)
        }
    }

    // MARK: - Resolution

    func resolveChallenge(_ challenge: Challenge) async throws {
        guard challenge.status == .active else { return }

        let ranking = challenge.ranking
        guard let leader = ranking.first else { return }

        let batch = db.batch()
        let challengeRef = challenges.document(challenge.id)

        let topValue = leader.value
        let winners = ranking.filter { $0.value == topValue }
        let isTie = winners.count > 1 || topValue == 0

        if isTie {
            // Refund every participant their stake.
            if challenge.wagerAmount > 0 {
                for pid in challenge.participantIDs {
                    batch.updateData(
                        ["pointsBalance": FieldValue.increment(Int64(challenge.wagerAmount))],
                        forDocument: users.document(pid)
                    )
                }
            }
            batch.updateData([
                "status": ChallengeStatus.completed.rawValue,
                "escrowedPoints": 0,
                "winnerID": FieldValue.delete()
            ], forDocument: challengeRef)
            try await batch.commit()
        } else {
            let winnerID = winners[0].id
            if challenge.escrowedPoints > 0 {
                batch.updateData(
                    ["pointsBalance": FieldValue.increment(Int64(challenge.escrowedPoints))],
                    forDocument: users.document(winnerID)
                )
            }
            batch.updateData([
                "status": ChallengeStatus.completed.rawValue,
                "escrowedPoints": 0,
                "winnerID": winnerID
            ], forDocument: challengeRef)
            try await batch.commit()

            let winnerName = challenge.name(for: winnerID)
            let event = FeedEvent(
                authorID: winnerID,
                authorUsername: winnerName,
                type: .challengeWon,
                message: "\(winnerName) won \(challenge.title)! 🏆",
                relatedID: challenge.id
            )
            try? await feedService.postEvent(event)
        }
    }

    func cancelChallenge(_ challenge: Challenge) async throws {
        guard challenge.status == .pending else { throw ChallengeError.notCancellable }

        let batch = db.batch()
        let challengeRef = challenges.document(challenge.id)

        if challenge.wagerAmount > 0 {
            // Everyone confirmed so far (creator + accepted invitees) gets refunded.
            for pid in challenge.participantIDs {
                batch.updateData(
                    ["pointsBalance": FieldValue.increment(Int64(challenge.wagerAmount))],
                    forDocument: users.document(pid)
                )
            }
        }
        batch.updateData([
            "status": ChallengeStatus.cancelled.rawValue,
            "escrowedPoints": 0
        ], forDocument: challengeRef)

        try await batch.commit()
    }

    // MARK: - Reading

    func fetchActiveChallenges(for userID: String) async throws -> [Challenge] {
        let snapshot = try await challenges
            .whereField("participantIDs", arrayContains: userID)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Challenge.self) }
            .filter { $0.status == .pending || $0.status == .active }
            .sorted { $0.endDate < $1.endDate }
    }

    func fetchPastChallenges(for userID: String) async throws -> [Challenge] {
        let snapshot = try await challenges
            .whereField("participantIDs", arrayContains: userID)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Challenge.self) }
            .filter { $0.status == .completed || $0.status == .cancelled }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchPendingInvites(for userID: String) async throws -> [ChallengeInvite] {
        let snapshot = try await invites
            .whereField("toUserID", isEqualTo: userID)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: ChallengeInvite.self) }
            .filter { $0.status == .pending }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Live single-challenge listener for the detail screen's wand duel bar.
    func attachChallengeListener(
        challengeID: String,
        onChange: @escaping (Challenge) -> Void
    ) -> ListenerRegistration {
        challenges.document(challengeID).addSnapshotListener { snapshot, _ in
            // On error `snapshot` is nil — keep the caller's last known state.
            guard let snapshot, let challenge = try? snapshot.data(as: Challenge.self) else { return }
            onChange(challenge)
        }
    }
}
