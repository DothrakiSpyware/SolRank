import SwiftUI

/// Bottom sheet detail for a single skill category — shows level, XP, contributing stats,
/// lifetime totals, and recent (week/month) contributions. All data derived from the
/// already-loaded Character (no extra Firestore calls).
struct SkillDetailSheet: View {
    let category: XPCategory
    let character: Character

    @Environment(\.dismiss) private var dismiss

    private var progress: CategoryProgress { character.progress(for: category) }
    private var feedingStats: [TrackedStat] {
        character.trackedStats.filter { $0.definition.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                progressCard
                feedsCard
                contributorsCard
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 12) {
            Text(category.icon).font(.system(size: 42))
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Level \(progress.level)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(category.color)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.gray)
            }
            .buttonStyle(.plain)
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(progress.totalXP) XP")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(progress.xpRemaining) to next")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.gray)
            }
            XPBar(progress: progress.progressToNext, color: category.color, height: 12)
        }
        .padding(14)
        .solCard()
    }

    private var feedsCard: some View {
        let names = feedingStats.map { $0.definition.name }
        let body: String = names.isEmpty
            ? "No tracked stats feed \(category.rawValue) yet. Add stats from the Character tab to start earning XP."
            : "\(category.rawValue) XP comes from: \(names.joined(separator: ", "))."
        return VStack(alignment: .leading, spacing: 6) {
            Text("WHAT FEEDS THIS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.gray)
            Text(body)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .solCard()
    }

    private var contributorsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.gray)
            if feedingStats.isEmpty {
                Text("—")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
            } else {
                ForEach(feedingStats) { stat in
                    statRow(stat)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .solCard()
    }

    private func statRow(_ stat: TrackedStat) -> some View {
        let unit = stat.definition.unit ?? ""
        let week = aggregate(statID: stat.id, withinDays: 7)
        let month = aggregate(statID: stat.id, withinDays: 30)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stat.definition.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(formatted(stat.lifetimeTotal)) \(unit) lifetime".trimmingCharacters(in: .whitespaces))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }
            HStack(spacing: 14) {
                miniStat(label: "Week", value: "\(formatted(week))")
                miniStat(label: "Month", value: "\(formatted(month))")
                if stat.definition.type == .boolean {
                    miniStat(label: "Streak", value: "🔥 \(stat.currentStreak)")
                }
                Spacer()
            }
        }
        .padding(.vertical, 6)
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.gray)
            Text(value)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(.white)
        }
    }

    /// Sums recent StatEntry values for `statID` within the last `days` days.
    /// Operates on the already-loaded `recentEntries` (capped) — no Firestore calls.
    private func aggregate(statID: String, withinDays days: Int) -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return character.recentEntries
            .filter { $0.statID == statID && $0.timestamp >= cutoff }
            .reduce(0) { $0 + $1.value }
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
