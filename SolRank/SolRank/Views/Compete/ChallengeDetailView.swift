import SwiftUI
import FirebaseFirestore

struct ChallengeDetailView: View {
    let initialChallenge: Challenge
    let currentUserID: String

    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var challenge: Challenge
    @State private var listener: ListenerRegistration?
    @State private var isCancelling = false

    private let service = ChallengeService()

    init(challenge: Challenge, currentUserID: String) {
        self.initialChallenge = challenge
        self.currentUserID = currentUserID
        _challenge = State(initialValue: challenge)
    }

    private var accent: Color { ChallengeStyle.accent(for: challenge) }
    private var isParticipant: Bool { challenge.participantIDs.contains(currentUserID) }
    private var isCreator: Bool { challenge.creatorID == currentUserID }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                duelSection
                standingsSection
                actionSection
            }
            .padding(20)
        }
        .background(Theme.background)
        .navigationTitle("Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: attachListener)
        .onDisappear(perform: detachListener)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(challenge.title)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                ForEach(challenge.statNames, id: \.self) { name in
                    Text(name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(accent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 16) {
                Label(goalText, systemImage: "target")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.gray)
                if challenge.wagerAmount > 0 {
                    Text("🪙 \(challenge.wagerAmount)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.gold)
                }
            }

            Text(endText)
                .font(.system(size: 13))
                .foregroundStyle(.gray)
        }
    }

    @ViewBuilder
    private var duelSection: some View {
        if challenge.participantIDs.count == 2 {
            let ranking = challenge.ranking
            WandDuelBar(
                leftName: challenge.name(for: ranking[0].id),
                leftValue: ranking[0].value,
                rightName: challenge.name(for: ranking[1].id),
                rightValue: ranking[1].value
            )
            .padding(16)
            .solCard()
        } else if challenge.participantIDs.count > 2 {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("STANDINGS")
                RankedProgressList(challenge: challenge)
            }
            .padding(16)
            .solCard()
        } else {
            VStack(spacing: 8) {
                Text("⏳").font(.system(size: 36))
                Text("Waiting for an opponent to accept")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .solCard()
        }
    }

    @ViewBuilder
    private var standingsSection: some View {
        if challenge.participantIDs.count == 2 {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("STANDINGS")
                ForEach(challenge.ranking, id: \.id) { entry in
                    HStack {
                        Text(challenge.name(for: entry.id))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        if entry.id == currentUserID {
                            Text("you").font(.system(size: 11)).foregroundStyle(.gray)
                        }
                        Spacer()
                        Text(format(entry.value))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(accent)
                    }
                    .padding(12)
                    .solCard()
                }
            }
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        switch challenge.status {
        case .active where isParticipant:
            Button {
                router.go(to: .home)
                dismiss()
            } label: {
                actionLabel("Log Progress", color: accent)
            }
        case .pending where isCreator:
            Button(role: .destructive) {
                cancelChallenge()
            } label: {
                actionLabel(isCancelling ? "Cancelling…" : "Cancel Challenge", color: .red)
            }
            .disabled(isCancelling)
        case .completed:
            winnerBanner
        default:
            EmptyView()
        }
    }

    private var winnerBanner: some View {
        VStack(spacing: 8) {
            Text("🏆").font(.system(size: 44))
            if let winner = challenge.winnerID {
                Text("\(challenge.name(for: winner)) won!")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gold)
                if challenge.wagerAmount > 0 {
                    Text("Pot awarded to the winner")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                }
            } else {
                Text("Ended in a tie — wagers refunded")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.gold.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func actionLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var goalText: String {
        switch challenge.goalType {
        case .firstToReach:
            return "First to \(format(challenge.goalValue ?? 0))"
        case .mostByEndDate:
            return "Most by end date"
        }
    }

    private var endText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let prefix = challenge.isExpired ? "Ended " : "Ends "
        return prefix + formatter.localizedString(for: challenge.endDate, relativeTo: Date())
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }

    // MARK: - Live listener

    private func attachListener() {
        listener = service.attachChallengeListener(challengeID: challenge.id) { updated in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                challenge = updated
            }
        }
    }

    private func detachListener() {
        listener?.remove()
        listener = nil
    }

    private func cancelChallenge() {
        isCancelling = true
        Task {
            do {
                try await service.cancelChallenge(challenge)
                await authVM.refreshUser()
                dismiss()
            } catch {
                isCancelling = false
            }
        }
    }
}
