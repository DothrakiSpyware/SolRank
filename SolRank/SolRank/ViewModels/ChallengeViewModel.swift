import Foundation
import Combine

@MainActor
final class ChallengeViewModel: ObservableObject {
    @Published var activeChallenges: [Challenge] = []
    @Published var pastChallenges: [Challenge] = []
    @Published var pendingInvites: [ChallengeInvite] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: ChallengeService
    private var currentUserID: String?

    init(service: ChallengeService? = nil) {
        self.service = service ?? ChallengeService()
    }

    // MARK: - Loading

    func loadData(for userID: String) async {
        currentUserID = userID
        isLoading = true
        defer { isLoading = false }
        do {
            async let active = service.fetchActiveChallenges(for: userID)
            async let past = service.fetchPastChallenges(for: userID)
            async let invites = service.fetchPendingInvites(for: userID)

            var loadedActive = try await active
            pastChallenges = try await past
            pendingInvites = try await invites

            // Lazily resolve any "most by end date" challenges whose deadline passed.
            await resolveExpired(in: &loadedActive)
            activeChallenges = loadedActive
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolveExpired(in challenges: inout [Challenge]) async {
        var stillActive: [Challenge] = []
        for challenge in challenges {
            if challenge.status == .active, challenge.isExpired {
                try? await service.resolveChallenge(challenge)
            } else {
                stillActive.append(challenge)
            }
        }
        challenges = stillActive
    }

    // MARK: - Invites

    func acceptInvite(_ invite: ChallengeInvite, user: AppUser) {
        Task {
            do {
                try await service.acceptInvite(invite, user: user)
                await loadData(for: user.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func declineInvite(_ invite: ChallengeInvite) {
        Task {
            do {
                try await service.declineInvite(invite)
                pendingInvites.removeAll { $0.id == invite.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Creation

    /// Validates and creates a challenge. `invitees` is a list of (id, name) pairs.
    func createChallenge(
        title: String,
        creator: AppUser,
        creatorName: String,
        statIDs: [String],
        statNames: [String],
        goalType: ChallengeGoalType,
        goalValue: Double?,
        endDate: Date,
        wagerAmount: Int,
        invitees: [(id: String, name: String)]
    ) async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Give your challenge a title."
            return false
        }
        guard (1...3).contains(statIDs.count) else {
            errorMessage = "Pick between 1 and 3 stats."
            return false
        }
        guard endDate > Date() else {
            errorMessage = "End date must be in the future."
            return false
        }
        guard wagerAmount >= 0, wagerAmount <= creator.pointsBalance else {
            errorMessage = "Wager can't exceed your \(creator.pointsBalance) points."
            return false
        }
        if goalType == .firstToReach, (goalValue ?? 0) <= 0 {
            errorMessage = "Set a target value to reach."
            return false
        }

        var challenge = Challenge(
            title: trimmedTitle,
            creatorID: creator.id,
            creatorName: creatorName,
            statIDs: statIDs,
            statNames: statNames,
            goalType: goalType,
            goalValue: goalType == .firstToReach ? goalValue : nil,
            endDate: endDate,
            wagerAmount: wagerAmount
        )

        let inviteModels = invitees.map { invitee in
            ChallengeInvite(
                challengeID: challenge.id,
                challengeTitle: trimmedTitle,
                fromUserID: creator.id,
                fromUsername: creatorName,
                toUserID: invitee.id,
                wagerAmount: wagerAmount,
                statNames: statNames,
                endDate: endDate
            )
        }

        // No invitees → solo challenge can start immediately.
        if inviteModels.isEmpty {
            challenge.status = .active
        }

        do {
            try await service.createChallenge(challenge, invites: inviteModels)
            await loadData(for: creator.id)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clearError() { errorMessage = nil }
}
