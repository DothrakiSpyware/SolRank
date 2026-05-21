import SwiftUI

struct CompeteView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var gameVM: GameViewModel
    @StateObject private var challengeVM = ChallengeViewModel()
    @StateObject private var leagueVM = LeagueViewModel()

    @State private var mode = 0          // 0 = Challenges, 1 = Leagues
    @State private var subTab = 0        // 0 = Active, 1 = Past
    @State private var showCreateChooser = false
    @State private var showCreateChallenge = false
    @State private var showCreateLeague = false

    private var userID: String { authVM.appUser?.id ?? "" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    modePicker
                    if mode == 0 { challengesContent } else { leaguesContent }
                }
                .padding(.vertical, 12)
            }
            .background(Theme.background)
            .navigationTitle("Compete")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateChooser = true } label: { Image(systemName: "plus") }
                }
            }
            .confirmationDialog("Create", isPresented: $showCreateChooser, titleVisibility: .visible) {
                Button("Challenge") { showCreateChallenge = true }
                Button("League") { showCreateLeague = true }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showCreateChallenge) {
                CreateChallengeView(challengeVM: challengeVM)
            }
            .sheet(isPresented: $showCreateLeague) {
                CreateLeagueView(leagueVM: leagueVM)
            }
            .refreshable { await reload() }
        }
        .task(id: userID) {
            guard !userID.isEmpty else { return }
            await reload()
            await gameVM.refreshChallenges(for: userID)
            await gameVM.refreshLeagues(for: userID)
        }
    }

    private func reload() async {
        await challengeVM.loadData(for: userID)
        await leagueVM.loadData(for: userID)
    }

    private var modePicker: some View {
        Picker("", selection: $mode) {
            Text("Challenges").tag(0)
            Text("Leagues").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
    }

    private var subTabPicker: some View {
        Picker("", selection: $subTab) {
            Text("Active").tag(0)
            Text("Past").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
    }

    // MARK: - Challenges

    @ViewBuilder
    private var challengesContent: some View {
        if !challengeVM.pendingInvites.isEmpty {
            invitesHeader("CHALLENGE INVITES")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(challengeVM.pendingInvites) { invite in
                        ChallengeInviteCard(
                            invite: invite,
                            canAfford: (authVM.appUser?.pointsBalance ?? 0) >= invite.wagerAmount,
                            onAccept: { if let user = authVM.appUser { challengeVM.acceptInvite(invite, user: user) } },
                            onDecline: { challengeVM.declineInvite(invite) }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        subTabPicker
        let items = subTab == 0 ? challengeVM.activeChallenges : challengeVM.pastChallenges
        if challengeVM.isLoading && items.isEmpty {
            ProgressView().tint(Theme.gold).padding(.top, 40)
        } else if items.isEmpty {
            emptyState(icon: subTab == 0 ? "⚔️" : "📜", text: subTab == 0 ? "No active challenges" : "No past challenges", hint: subTab == 0)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(items) { challenge in
                    NavigationLink {
                        ChallengeDetailView(challenge: challenge, currentUserID: userID)
                    } label: {
                        ChallengeRowView(challenge: challenge, currentUserID: userID, dimmed: subTab == 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Leagues

    @ViewBuilder
    private var leaguesContent: some View {
        if !leagueVM.pendingInvites.isEmpty {
            invitesHeader("LEAGUE INVITES")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(leagueVM.pendingInvites) { invite in
                        LeagueInviteCard(
                            invite: invite,
                            canAfford: (authVM.appUser?.pointsBalance ?? 0) >= invite.entryWager,
                            onAccept: { if let user = authVM.appUser { leagueVM.acceptInvite(invite, user: user) } },
                            onDecline: { leagueVM.declineInvite(invite) }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        subTabPicker
        let items = subTab == 0 ? leagueVM.activeLeagues : leagueVM.pastLeagues
        if leagueVM.isLoading && items.isEmpty {
            ProgressView().tint(Theme.gold).padding(.top, 40)
        } else if items.isEmpty {
            emptyState(icon: subTab == 0 ? "🏆" : "📜", text: subTab == 0 ? "No active leagues" : "No past leagues", hint: subTab == 0)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(items) { league in
                    NavigationLink {
                        LeagueDetailView(league: league, currentUserID: userID, initialEntries: leagueVM.entries(for: league))
                    } label: {
                        LeagueRowView(league: league, entries: leagueVM.entries(for: league), currentUserID: userID, dimmed: subTab == 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Shared pieces

    private func invitesHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }

    private func emptyState(icon: String, text: String, hint: Bool) -> some View {
        VStack(spacing: 10) {
            Text(icon).font(.system(size: 48))
            Text(text).font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            if hint {
                Text("Tap + to start one.").font(.system(size: 14)).foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Challenge invite card

private struct ChallengeInviteCard: View {
    let invite: ChallengeInvite
    let canAfford: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        InviteCardShell(
            title: invite.challengeTitle,
            from: invite.fromUsername,
            subtitle: invite.statNames.joined(separator: " · "),
            wager: invite.wagerAmount,
            canAfford: canAfford,
            onAccept: onAccept,
            onDecline: onDecline
        )
    }
}

// MARK: - League invite card

private struct LeagueInviteCard: View {
    let invite: LeagueInvite
    let canAfford: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        InviteCardShell(
            title: invite.leagueName,
            from: invite.fromUsername,
            subtitle: invite.statNames.joined(separator: " · "),
            wager: invite.entryWager,
            canAfford: canAfford,
            onAccept: onAccept,
            onDecline: onDecline
        )
    }
}

// MARK: - Shared invite card layout

private struct InviteCardShell: View {
    let title: String
    let from: String
    let subtitle: String
    let wager: Int
    let canAfford: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("from \(from)")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .lineLimit(1)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(action: onAccept) {
                    Text(wager > 0 ? "Accept · 🪙\(wager)" : "Accept")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(canAfford ? Color.green : Color.gray)
                        .clipShape(Capsule())
                }
                .disabled(!canAfford)

                Button(action: onDecline) {
                    Text("Decline")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.red.opacity(0.85))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .frame(width: 240, height: 170)
        .background(Color(white: 0.16))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
