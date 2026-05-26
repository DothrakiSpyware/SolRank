import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var gameVM: GameViewModel

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if gameVM.homeStats.isEmpty {
                        emptyState
                    } else {
                        numericSection
                        checkInSection
                        todaySummary
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Theme.background)
            .navigationTitle("Log")
        }
    }

    private var numericStats: [TrackedStat] {
        gameVM.homeStats.filter { $0.definition.type == .numeric }
    }

    private var booleanStats: [TrackedStat] {
        gameVM.homeStats.filter { $0.definition.type == .boolean }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("⚡️").font(.system(size: 56))
            Text("No stats on your home screen yet.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text("Add stats from the Character tab to start logging.")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Numeric (2-col grid)

    @ViewBuilder
    private var numericSection: some View {
        if !numericStats.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("TODAY'S STATS")
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(numericStats) { stat in
                        StatQuickLogButton(stat: stat) { amount in
                            gameVM.logNumeric(statID: stat.id, amount: amount)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Boolean (sliders)

    @ViewBuilder
    private var checkInSection: some View {
        if !booleanStats.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("DAILY CHECK-INS")
                VStack(spacing: 10) {
                    ForEach(booleanStats) { stat in
                        DailyCheckInSlider(
                            stat: stat,
                            onLogYes: { gameVM.setBoolean(statID: stat.id, completed: true) },
                            onLogNo: { gameVM.logBooleanNo(statID: stat.id) },
                            onChangeEmoji: { emoji in
                                gameVM.setCelebrationEmoji(statID: stat.id, emoji: emoji)
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Summary

    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("TODAY'S SUMMARY")
            ForEach(gameVM.homeStats) { stat in
                HStack {
                    Text(stat.definition.category?.icon ?? "⭐️")
                    Text(stat.definition.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    if stat.definition.type == .boolean {
                        Text(stat.isCompletedToday ? "Done · 🔥\(stat.currentStreak)" : (stat.isLoggedNoToday ? "Logged 😔" : "Not yet"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(stat.isCompletedToday ? Theme.gold : .gray)
                    } else {
                        Text(format(stat.dailyValue) + " " + (stat.definition.unit ?? ""))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.gold)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .solCard()
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.gray)
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
