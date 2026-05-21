import SwiftUI

struct CreateChallengeView: View {
    @ObservedObject var challengeVM: ChallengeViewModel

    @EnvironmentObject private var gameVM: GameViewModel
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedStatIDs: Set<String> = []
    @State private var goalType: ChallengeGoalType = .mostByEndDate
    @State private var goalValueText = ""
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var wager = 0
    @State private var selectedFriendIDs: Set<String> = []
    @State private var isSubmitting = false

    private let maxStats = 3

    private var trackedStats: [TrackedStat] { gameVM.character?.trackedStats ?? [] }
    private var friendIDs: [String] { authVM.appUser?.friendIDs ?? [] }
    private var points: Int { authVM.appUser?.pointsBalance ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                statSection
                goalSection
                wagerSection
                inviteSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { submit() }
                        .fontWeight(.bold)
                        .disabled(!canCreate || isSubmitting)
                }
            }
            .alert("Couldn't Create", isPresented: Binding(
                get: { challengeVM.errorMessage != nil },
                set: { if !$0 { challengeVM.clearError() } }
            )) {
                Button("OK") { challengeVM.clearError() }
            } message: {
                Text(challengeVM.errorMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section {
            TextField("Challenge title", text: $title)
        }
        .listRowBackground(Theme.card)
    }

    private var statSection: some View {
        Section {
            if trackedStats.isEmpty {
                Text("Add stats on the Character tab first.")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            } else {
                ForEach(trackedStats) { stat in
                    statRow(stat)
                }
            }
        } header: {
            Text("Stats (\(selectedStatIDs.count)/\(maxStats))")
        }
        .listRowBackground(Theme.card)
    }

    private func statRow(_ stat: TrackedStat) -> some View {
        let isSelected = selectedStatIDs.contains(stat.id)
        let atLimit = selectedStatIDs.count >= maxStats && !isSelected
        return Button {
            toggleStat(stat.id, isSelected: isSelected)
        } label: {
            HStack(spacing: 10) {
                Text(stat.definition.category?.icon ?? "⭐️")
                Text(stat.definition.name)
                    .foregroundStyle(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(stat.definition.category?.color ?? Theme.gold)
                }
            }
        }
        .disabled(atLimit)
        .opacity(atLimit ? 0.4 : 1)
    }

    private var goalSection: some View {
        Section("Goal") {
            Picker("Goal type", selection: $goalType) {
                Text("Most by end date").tag(ChallengeGoalType.mostByEndDate)
                Text("First to reach").tag(ChallengeGoalType.firstToReach)
            }
            .pickerStyle(.segmented)

            if goalType == .firstToReach {
                TextField("Target value", text: $goalValueText)
                    .keyboardType(.decimalPad)
            }

            DatePicker("Ends", selection: $endDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
        }
        .listRowBackground(Theme.card)
    }

    private var wagerSection: some View {
        Section {
            Stepper(value: $wager, in: 0...max(0, points), step: 10) {
                HStack {
                    Text("Wager")
                    Spacer()
                    Text("🪙 \(wager)").foregroundStyle(Theme.gold)
                }
            }
            Text("You have \(points) points.")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
        } header: {
            Text("Wager")
        }
        .listRowBackground(Theme.card)
    }

    private var inviteSection: some View {
        Section("Invite Friends") {
            if friendIDs.isEmpty {
                Text("Add friends first to invite them.")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            } else {
                ForEach(friendIDs, id: \.self) { friendID in
                    Button {
                        toggleFriend(friendID)
                    } label: {
                        HStack {
                            Text(friendID)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Spacer()
                            if selectedFriendIDs.contains(friendID) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.gold)
                            }
                        }
                    }
                }
            }
        }
        .listRowBackground(Theme.card)
    }

    // MARK: - Logic

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        (1...maxStats).contains(selectedStatIDs.count)
    }

    private func toggleStat(_ id: String, isSelected: Bool) {
        if isSelected { selectedStatIDs.remove(id) }
        else if selectedStatIDs.count < maxStats { selectedStatIDs.insert(id) }
    }

    private func toggleFriend(_ id: String) {
        if selectedFriendIDs.contains(id) { selectedFriendIDs.remove(id) }
        else { selectedFriendIDs.insert(id) }
    }

    private func submit() {
        guard let user = authVM.appUser else { return }
        let creatorName = gameVM.character?.name ?? user.displayName

        let chosen = trackedStats.filter { selectedStatIDs.contains($0.id) }
        let statIDs = chosen.map(\.id)
        let statNames = chosen.map(\.definition.name)
        let invitees = selectedFriendIDs.map { (id: $0, name: "Friend") }

        isSubmitting = true
        Task {
            let ok = await challengeVM.createChallenge(
                title: title,
                creator: user,
                creatorName: creatorName,
                statIDs: statIDs,
                statNames: statNames,
                goalType: goalType,
                goalValue: Double(goalValueText),
                endDate: endDate,
                wagerAmount: wager,
                invitees: invitees
            )
            isSubmitting = false
            if ok {
                await authVM.refreshUser()
                await gameVM.refreshChallenges(for: user.id)
                dismiss()
            }
        }
    }
}
