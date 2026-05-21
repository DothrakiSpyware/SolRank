import SwiftUI

struct CreateLeagueView: View {
    @ObservedObject var leagueVM: LeagueViewModel

    @EnvironmentObject private var gameVM: GameViewModel
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var leagueDescription = ""
    @State private var selectedStatIDs: Set<String> = []
    @State private var pointsPerUnit: [String: String] = [:]
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var prizeStructure: PrizeStructure = .winnerTakesAll
    @State private var entryWager = 0
    @State private var limitParticipants = false
    @State private var maxParticipants = 10
    @State private var selectedFriendIDs: Set<String> = []
    @State private var isSubmitting = false

    /// League stats must map to a hardlocked XP category (custom stats excluded).
    private var eligibleStats: [TrackedStat] {
        (gameVM.character?.trackedStats ?? []).filter { $0.definition.category != nil }
    }
    private var friendIDs: [String] { authVM.appUser?.friendIDs ?? [] }
    private var points: Int { authVM.appUser?.pointsBalance ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                statSection
                scheduleSection
                prizeSection
                inviteSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("New League")
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
                get: { leagueVM.errorMessage != nil },
                set: { if !$0 { leagueVM.clearError() } }
            )) {
                Button("OK") { leagueVM.clearError() }
            } message: {
                Text(leagueVM.errorMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section {
            TextField("League name", text: $name)
            TextField("Description (optional)", text: $leagueDescription, axis: .vertical)
        }
        .listRowBackground(Theme.card)
    }

    private var statSection: some View {
        Section {
            if eligibleStats.isEmpty {
                Text("Add stats on the Character tab first.")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            } else {
                ForEach(eligibleStats) { stat in
                    statRow(stat)
                }
            }
        } header: {
            Text("Scoring Stats (\(selectedStatIDs.count))")
        } footer: {
            Text("Set how many points each unit (or each log for yes/no stats) is worth.")
        }
        .listRowBackground(Theme.card)
    }

    private func statRow(_ stat: TrackedStat) -> some View {
        let isSelected = selectedStatIDs.contains(stat.id)
        return VStack(spacing: 8) {
            Button {
                toggleStat(stat.id)
            } label: {
                HStack(spacing: 10) {
                    Text(stat.definition.category?.icon ?? "⭐️")
                    Text(stat.definition.name).foregroundStyle(.white)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? (stat.definition.category?.color ?? Theme.gold) : .gray)
                }
            }
            if isSelected {
                HStack {
                    Text("Points per \(stat.definition.type == .boolean ? "log" : "unit")")
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                    Spacer()
                    TextField("0", text: bindingForPoints(stat.id))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                }
            }
        }
    }

    private var scheduleSection: some View {
        Section("Schedule") {
            DatePicker("Starts", selection: $startDate, in: Calendar.current.startOfDay(for: Date())..., displayedComponents: .date)
            Toggle("Set an end date", isOn: $hasEndDate)
            if hasEndDate {
                DatePicker("Ends", selection: $endDate, in: startDate..., displayedComponents: .date)
            }
        }
        .listRowBackground(Theme.card)
    }

    private var prizeSection: some View {
        Section("Prizes & Entry") {
            Picker("Prize structure", selection: $prizeStructure) {
                ForEach(PrizeStructure.allCases, id: \.self) { structure in
                    Text(structure.displayName).tag(structure)
                }
            }
            Stepper(value: $entryWager, in: 0...max(0, points), step: 10) {
                HStack {
                    Text("Entry wager")
                    Spacer()
                    Text("🪙 \(entryWager)").foregroundStyle(Theme.gold)
                }
            }
            Toggle("Limit participants", isOn: $limitParticipants)
            if limitParticipants {
                Stepper(value: $maxParticipants, in: 2...50) {
                    Text("Max \(maxParticipants) members")
                }
            }
            Text("You have \(points) points.")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
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
                            Text(friendID).foregroundStyle(.white).lineLimit(1)
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
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedStatIDs.isEmpty
    }

    private func bindingForPoints(_ statID: String) -> Binding<String> {
        Binding(
            get: { pointsPerUnit[statID] ?? "" },
            set: { pointsPerUnit[statID] = $0 }
        )
    }

    private func toggleStat(_ id: String) {
        if selectedStatIDs.contains(id) {
            selectedStatIDs.remove(id)
            pointsPerUnit[id] = nil
        } else {
            selectedStatIDs.insert(id)
        }
    }

    private func toggleFriend(_ id: String) {
        if selectedFriendIDs.contains(id) { selectedFriendIDs.remove(id) }
        else { selectedFriendIDs.insert(id) }
    }

    private func submit() {
        guard let user = authVM.appUser else { return }
        let creatorName = gameVM.character?.name ?? user.displayName

        let configs: [LeagueStatConfig] = eligibleStats
            .filter { selectedStatIDs.contains($0.id) }
            .compactMap { stat in
                guard let category = stat.definition.category else { return nil }
                return LeagueStatConfig(
                    statID: stat.id,
                    statName: stat.definition.name,
                    category: category,
                    pointsPerUnit: Double(pointsPerUnit[stat.id] ?? "") ?? 0,
                    isBooleanStat: stat.definition.type == .boolean
                )
            }

        let invitees = selectedFriendIDs.map { (id: $0, name: "Friend") }

        isSubmitting = true
        Task {
            let ok = await leagueVM.createLeague(
                name: name,
                description: leagueDescription,
                creator: user,
                creatorName: creatorName,
                statConfigs: configs,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                prizeStructure: prizeStructure,
                entryWager: entryWager,
                maxParticipants: limitParticipants ? maxParticipants : nil,
                invitees: invitees
            )
            isSubmitting = false
            if ok {
                await authVM.refreshUser()
                await gameVM.refreshLeagues(for: user.id)
                dismiss()
            }
        }
    }
}
