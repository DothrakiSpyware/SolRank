import SwiftUI
import FirebaseFirestore

struct LeagueDetailView: View {
    let league: League
    let currentUserID: String
    let initialEntries: [LeagueEntry]

    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var leaderboard: [LeagueEntry]
    @State private var listener: ListenerRegistration?
    @State private var showScoring = false
    @State private var isCancelling = false

    private let service = LeagueService()

    init(league: League, currentUserID: String, initialEntries: [LeagueEntry]) {
        self.league = league
        self.currentUserID = currentUserID
        self.initialEntries = initialEntries
        _leaderboard = State(initialValue: initialEntries)
    }

    private var isCreator: Bool { league.creatorID == currentUserID }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                if league.status == .completed { winnerBanner }
                leaderboardSection
                scoringSection
                actionSection
            }
            .padding(20)
        }
        .background(Theme.background)
        .navigationTitle("League")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: attachListener)
        .onDisappear(perform: detachListener)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(league.name)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            if !league.description.isEmpty {
                Text(league.description)
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }

            HStack(spacing: 8) {
                statusBadge
                Text(league.prizeStructure.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.gold.opacity(0.15))
                    .clipShape(Capsule())
            }

            HStack(spacing: 16) {
                Label(dateText, systemImage: "calendar")
                if league.entryWager > 0 {
                    Text("🪙 \(league.entryWager) entry")
                        .foregroundStyle(Theme.gold)
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.gray)
        }
    }

    private var statusBadge: some View {
        let color: Color = {
            switch league.status {
            case .upcoming: return .orange
            case .active: return .green
            case .completed: return Theme.gold
            case .cancelled: return .gray
            }
        }()
        return Text(league.statusDisplay)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("LEADERBOARD")
            if leaderboard.isEmpty {
                Text("No standings yet — start logging!")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .padding(.vertical, 12)
            } else {
                ForEach(leaderboard) { entry in
                    leaderboardRow(entry)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: leaderboard)
            }
        }
    }

    private func leaderboardRow(_ entry: LeagueEntry) -> some View {
        let isMe = entry.userID == currentUserID
        return HStack(spacing: 12) {
            Text(rankPrefix(entry.rank))
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(rankColor(entry.rank))
                .frame(width: 34, alignment: .leading)

            Circle()
                .fill(rankColor(entry.rank).opacity(0.85))
                .frame(width: 34, height: 34)
                .overlay(
                    Text(String(entry.username.prefix(1)).uppercased())
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let breakdown = breakdownText(entry) {
                    Text(breakdown)
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text("\(format(entry.totalPoints)) pts")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(Theme.gold)
        }
        .padding(12)
        .background(isMe ? Theme.gold.opacity(0.12) : Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isMe ? Theme.gold : Theme.cardStroke, lineWidth: isMe ? 1.5 : 1)
        )
    }

    // MARK: - Scoring breakdown

    private var scoringSection: some View {
        DisclosureGroup(isExpanded: $showScoring) {
            VStack(spacing: 8) {
                ForEach(league.statConfigs) { config in
                    HStack {
                        Text(config.category.icon)
                        Text(config.statName)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(format(config.pointsPerUnit)) pts/\(config.isBooleanStat ? "log" : "unit")")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.top, 8)
        } label: {
            Text("SCORING")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.gray)
        }
        .tint(.gray)
        .padding(14)
        .solCard()
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionSection: some View {
        if isCreator, league.status == .upcoming || league.status == .active {
            Button(role: .destructive) {
                cancelLeague()
            } label: {
                Text(isCancelling ? "Cancelling…" : "Cancel League")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isCancelling)
        }
    }

    private var winnerBanner: some View {
        VStack(spacing: 8) {
            Text("🏆").font(.system(size: 44))
            if let winner = leaderboard.first, winner.totalPoints > 0 {
                Text("\(winner.username) won!")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gold)
            } else {
                Text("League complete")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(league.prizeStructure.displayName)
                .font(.system(size: 13))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.gold.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rankPrefix(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Theme.gold
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return .gray
        }
    }

    private func breakdownText(_ entry: LeagueEntry) -> String? {
        let parts = entry.statBreakdown
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map { "\(statName(for: $0.key)) \(format($0.value))" }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func statName(for statID: String) -> String {
        league.statConfigs.first { $0.statID == statID }?.statName ?? statID
    }

    private var dateText: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        let start = df.string(from: league.startDate)
        if let end = league.endDate {
            return "\(start) – \(df.string(from: end))"
        }
        return "Starts \(start) · Ongoing"
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }

    // MARK: - Live listener

    private func attachListener() {
        listener = service.attachLeaderboardListener(leagueID: league.id) { entries in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                leaderboard = entries
            }
        }
    }

    private func detachListener() {
        listener?.remove()
        listener = nil
    }

    private func cancelLeague() {
        isCancelling = true
        Task {
            do {
                try await service.cancelLeague(league)
                await authVM.refreshUser()
                dismiss()
            } catch {
                isCancelling = false
            }
        }
    }
}
