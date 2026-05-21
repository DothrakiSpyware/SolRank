import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var gameVM: GameViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if gameVM.homeStats.isEmpty {
                        emptyState
                    } else {
                        quickLogSection
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

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !numericStats.isEmpty {
                sectionTitle("QUICK LOG")
                ForEach(numericStats) { stat in
                    QuickLogButton(stat: stat) { amount in
                        gameVM.logNumeric(statID: stat.id, amount: amount)
                    }
                }
            }
            if !booleanStats.isEmpty {
                sectionTitle("TODAY'S CHECK-INS")
                ForEach(booleanStats) { stat in
                    BooleanLogRow(stat: stat) { done in
                        gameVM.setBoolean(statID: stat.id, completed: done)
                    }
                }
            }
        }
    }

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
                        Text(stat.isCompletedToday ? "Done · 🔥\(stat.currentStreak)" : "Not yet")
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

// MARK: - Quick log button (numeric)

private struct QuickLogButton: View {
    let stat: TrackedStat
    let onLog: (Double) -> Void

    @State private var showManualEntry = false
    @State private var manualValue = ""
    @State private var pulse = false

    private var color: Color { stat.definition.category?.color ?? Theme.gold }

    var body: some View {
        Button {
            onLog(stat.increment)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { pulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { pulse = false }
        } label: {
            HStack(spacing: 14) {
                Text(stat.definition.category?.icon ?? "⭐️")
                    .font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.definition.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Today: \(format(stat.dailyValue)) \(stat.definition.unit ?? "")")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
                Spacer()
                Text("+\(format(stat.increment))")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(color)
                    .clipShape(Capsule())
            }
            .padding(14)
            .solCard()
            .scaleEffect(pulse ? 1.03 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture().onEnded { _ in showManualEntry = true })
        .alert("Log \(stat.definition.name)", isPresented: $showManualEntry) {
            TextField("Amount", text: $manualValue)
                .keyboardType(.decimalPad)
            Button("Log") {
                if let value = Double(manualValue), value != 0 { onLog(value) }
                manualValue = ""
            }
            Button("Cancel", role: .cancel) { manualValue = "" }
        } message: {
            Text("Enter a specific amount to log.")
        }
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

// MARK: - Boolean log row

private struct BooleanLogRow: View {
    let stat: TrackedStat
    let onSet: (Bool) -> Void

    var body: some View {
        let done = stat.isCompletedToday
        return HStack(spacing: 14) {
            Text(stat.definition.category?.icon ?? "⭐️")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.definition.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("🔥 \(stat.currentStreak) day streak")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }
            Spacer()
            Button {
                onSet(!done)
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            } label: {
                Text(done ? "Done" : "Mark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(done ? .black : .white)
                    .frame(width: 76, height: 38)
                    .background(done ? Theme.gold : Color.white.opacity(0.12))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .solCard()
    }
}
