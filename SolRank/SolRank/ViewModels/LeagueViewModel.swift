import Foundation
import Combine

@MainActor
final class LeagueViewModel: ObservableObject {
    @Published var activeLeagues: [League] = []
    @Published var pastLeagues: [League] = []
    @Published var pendingInvites: [LeagueInvite] = []
    @Published var leaderboards: [String: [LeagueEntry]] = [:]   // leagueID → ranked entries
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: LeagueService

    init(service: LeagueService? = nil) {
        self.service = service ?? LeagueService()
    }

    // MARK: - Loading

    func loadData(for userID: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let active = service.fetchActiveLeagues(for: userID)
            async let past = service.fetchPastLeagues(for: userID)
            async let invites = service.fetchPendingInvites(for: userID)

            var loadedActive = try await active
            pastLeagues = try await past
            pendingInvites = try await invites

            await resolveExpired(in: &loadedActive)
            activeLeagues = loadedActive

            await loadLeaderboards(for: loadedActive + pastLeagues)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolveExpired(in leagues: inout [League]) async {
        var stillActive: [League] = []
        for league in leagues {
            if league.status == .active, league.isExpired {
                try? await service.resolveLeague(league)
            } else {
                stillActive.append(league)
            }
        }
        leagues = stillActive
    }

    private func loadLeaderboards(for leagues: [League]) async {
        var result: [String: [LeagueEntry]] = [:]
        for league in leagues {
            if let entries = try? await service.fetchLeaderboard(leagueID: league.id) {
                result[league.id] = entries
            }
        }
        leaderboards = result
    }

    func entries(for league: League) -> [LeagueEntry] { leaderboards[league.id] ?? [] }

    // MARK: - Invites

    func acceptInvite(_ invite: LeagueInvite, user: AppUser) {
        Task {
            do {
                try await service.acceptInvite(invite, user: user)
                await loadData(for: user.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func declineInvite(_ invite: LeagueInvite) {
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

    func createLeague(
        name: String,
        description: String,
        creator: AppUser,
        creatorName: String,
        statConfigs: [LeagueStatConfig],
        startDate: Date,
        endDate: Date?,
        prizeStructure: PrizeStructure,
        entryWager: Int,
        maxParticipants: Int?,
        invitees: [(id: String, name: String)]
    ) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Give your league a name."
            return false
        }
        guard !statConfigs.isEmpty else {
            errorMessage = "Add at least one scoring stat."
            return false
        }
        guard statConfigs.allSatisfy({ $0.pointsPerUnit > 0 }) else {
            errorMessage = "Every stat needs points per unit greater than 0."
            return false
        }
        guard startDate >= Calendar.current.startOfDay(for: Date()) else {
            errorMessage = "Start date can't be in the past."
            return false
        }
        if let endDate, endDate <= startDate {
            errorMessage = "End date must be after the start date."
            return false
        }
        guard entryWager >= 0, entryWager <= creator.pointsBalance else {
            errorMessage = "Entry wager can't exceed your \(creator.pointsBalance) points."
            return false
        }

        let league = League(
            name: trimmedName,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            creatorID: creator.id,
            creatorName: creatorName,
            statConfigs: statConfigs,
            startDate: startDate,
            endDate: endDate,
            prizeStructure: prizeStructure,
            entryWager: entryWager,
            maxParticipants: maxParticipants
        )

        let inviteModels = invitees.map { invitee in
            LeagueInvite(
                leagueID: league.id,
                leagueName: trimmedName,
                fromUserID: creator.id,
                fromUsername: creatorName,
                toUserID: invitee.id,
                entryWager: entryWager,
                statNames: statConfigs.map(\.statName),
                startDate: startDate
            )
        }

        do {
            try await service.createLeague(league, invites: inviteModels)
            await loadData(for: creator.id)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clearError() { errorMessage = nil }
}
