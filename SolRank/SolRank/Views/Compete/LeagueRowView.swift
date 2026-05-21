import SwiftUI

struct LeagueRowView: View {
    let league: League
    let entries: [LeagueEntry]
    let currentUserID: String
    var dimmed: Bool = false

    private var myEntry: LeagueEntry? { entries.first { $0.userID == currentUserID } }

    var body: some View {
        HStack(spacing: 0) {
            // Leagues use a gold border — they feel more prestigious than challenges.
            Rectangle().fill(Theme.gold).frame(width: 4)

            VStack(alignment: .leading, spacing: 10) {
                header
                statIcons
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
                Text(league.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(league.memberCount) members")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }
            Spacer()
            if league.entryWager > 0 {
                Text("🪙 \(league.entryWager)")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Theme.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.gold.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    private var statIcons: some View {
        HStack(spacing: 6) {
            ForEach(league.statConfigs) { config in
                Text(config.category.icon)
                    .font(.system(size: 16))
            }
            Spacer()
        }
    }

    private var footer: some View {
        HStack {
            if let entry = myEntry {
                Text("Rank #\(entry.rank) of \(league.memberCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(entry.rank == 1 ? Theme.gold : .white)
                Text("· \(format(entry.totalPoints)) pts")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            } else {
                Text(league.statusDisplay)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.gray)
            }
            Spacer()
            Text(endText)
                .font(.system(size: 12))
                .foregroundStyle(.gray)
        }
    }

    private var endText: String {
        guard let endDate = league.endDate else { return "No end date" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let prefix = league.isExpired ? "Ended " : "Ends "
        return prefix + formatter.localizedString(for: endDate, relativeTo: Date())
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
