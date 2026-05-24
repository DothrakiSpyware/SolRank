import SwiftUI

struct ChallengeRowView: View {
    let challenge: Challenge
    let currentUserID: String
    var dimmed: Bool = false

    private var accent: Color { ChallengeStyle.accent(for: challenge) }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(accent).frame(width: 4)

            VStack(alignment: .leading, spacing: 10) {
                header
                Text(challenge.statNames.joined(separator: " · "))
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .lineLimit(1)

                miniStandings

                footer
            }
            .padding(14)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
        .opacity(dimmed ? 0.6 : 1)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Text(participantSummary)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
            Spacer()
            if challenge.wagerAmount > 0 {
                Text("🪙 \(challenge.wagerAmount)")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Theme.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.gold.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var miniStandings: some View {
        let ranking = challenge.ranking
        if ranking.count >= 2 {
            let leader = ranking[0]
            let runner = ranking[1]
            WandDuelBar(
                leftName: challenge.name(for: leader.id),
                leftValue: leader.value,
                rightName: challenge.name(for: runner.id),
                rightValue: runner.value
            )
        } else if let solo = ranking.first {
            HStack {
                Text(challenge.name(for: solo.id))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(format(solo.value))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accent)
            }
        }
    }

    private var footer: some View {
        HStack {
            statusBadge
            Spacer()
            Text(endText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.gray)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch challenge.status {
        case .pending:
            badge("Pending", color: .orange)
        case .active:
            badge("Active", color: .green)
        case .completed:
            if challenge.winnerID == currentUserID {
                badge("You won 🏆", color: Theme.gold)
            } else if let winner = challenge.winnerID {
                badge("Won by \(challenge.name(for: winner))", color: .gray)
            } else {
                badge("Tied", color: .gray)
            }
        case .cancelled:
            badge("Cancelled", color: .gray)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private var participantSummary: String {
        let names = challenge.participantIDs.map { challenge.name(for: $0) }
        return names.joined(separator: ", ")
    }

    private var endText: String {
        if challenge.status == .active || challenge.status == .pending {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "Ends " + formatter.localizedString(for: challenge.endDate, relativeTo: Date())
        }
        return ""
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
