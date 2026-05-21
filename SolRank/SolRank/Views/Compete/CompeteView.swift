import SwiftUI

struct CompeteView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var gameVM: GameViewModel
    @StateObject private var viewModel = ChallengeViewModel()

    @State private var tab = 0   // 0 = Active, 1 = Past
    @State private var showCreate = false

    private var userID: String { authVM.appUser?.id ?? "" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !viewModel.pendingInvites.isEmpty {
                        invitesSection
                    }
                    picker
                    challengeList
                }
                .padding(.vertical, 12)
            }
            .background(Theme.background)
            .navigationTitle("Compete")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateChallengeView(challengeVM: viewModel)
            }
            .refreshable { await viewModel.loadData(for: userID) }
        }
        .task(id: userID) {
            guard !userID.isEmpty else { return }
            await viewModel.loadData(for: userID)
            await gameVM.refreshChallenges(for: userID)
        }
    }

    // MARK: - Invites

    private var invitesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("INVITES")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.pendingInvites) { invite in
                        InviteCard(
                            invite: invite,
                            canAfford: (authVM.appUser?.pointsBalance ?? 0) >= invite.wagerAmount,
                            onAccept: {
                                if let user = authVM.appUser { viewModel.acceptInvite(invite, user: user) }
                            },
                            onDecline: { viewModel.declineInvite(invite) }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Picker + list

    private var picker: some View {
        Picker("", selection: $tab) {
            Text("Active").tag(0)
            Text("Past").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var challengeList: some View {
        let items = tab == 0 ? viewModel.activeChallenges : viewModel.pastChallenges
        if viewModel.isLoading && items.isEmpty {
            ProgressView().tint(Theme.gold).padding(.top, 40)
        } else if items.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 12) {
                ForEach(items) { challenge in
                    NavigationLink {
                        ChallengeDetailView(challenge: challenge, currentUserID: userID)
                    } label: {
                        ChallengeRowView(
                            challenge: challenge,
                            currentUserID: userID,
                            dimmed: tab == 1
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text(tab == 0 ? "⚔️" : "📜").font(.system(size: 48))
            Text(tab == 0 ? "No active challenges" : "No past challenges")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            if tab == 0 {
                Text("Tap + to start one.")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }
}

// MARK: - Invite card

private struct InviteCard: View {
    let invite: ChallengeInvite
    let canAfford: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(invite.challengeTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text("from \(invite.fromUsername)")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
            Text(invite.statNames.joined(separator: " · "))
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .lineLimit(1)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(action: onAccept) {
                    Text(invite.wagerAmount > 0 ? "Accept · 🪙\(invite.wagerAmount)" : "Accept")
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
