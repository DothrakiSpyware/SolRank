import SwiftUI

struct CharacterView: View {
    @EnvironmentObject private var gameVM: GameViewModel
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var selectedSkill: XPCategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let character = gameVM.character {
                    VStack(spacing: 24) {
                        topCard(character)
                        statSheet(character)
                        if !character.customXPBars.isEmpty {
                            customBars(character)
                        }
                        trackedStatsList(character)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                } else {
                    Text("No character yet.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 80)
                }
            }
            .background(Theme.background)
            .navigationTitle("Character")
            .sheet(item: $selectedSkill) { category in
                if let character = gameVM.character {
                    SkillDetailSheet(category: category, character: character)
                }
            }
        }
    }

    // MARK: - Top card (RuneScape style)

    private func topCard(_ character: Character) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 8) {
                CharacterSprite(appearance: character.appearance, size: 96)
                Text(character.name)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Lv.")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.gray)
                    Text("\(character.overallLevel)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.gold)
                }
                HStack(spacing: 4) {
                    Text("⚡")
                    Text("\(authVM.appUser?.pointsBalance ?? 0) pts")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                Divider().background(Color.white.opacity(0.1))
                VStack(spacing: 4) {
                    ForEach(XPCategory.allCases, id: \.self) { category in
                        skillRow(category, progress: character.progress(for: category))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .solCard()
    }

    private func skillRow(_ category: XPCategory, progress: CategoryProgress) -> some View {
        Button {
            selectedSkill = category
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 6) {
                Text(abbreviation(category))
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.gray)
                    .frame(width: 28, alignment: .leading)
                Text("Lv.\(progress.level)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, alignment: .leading)
                blockBar(progress: progress.progressToNext, color: category.color)
                Text(category.icon)
                    .font(.system(size: 12))
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// RuneScape-style 4-block segmented XP bar.
    private func blockBar(progress: Double, color: Color) -> some View {
        let filled = Int((progress * 4).rounded())
        return HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(i < filled ? color : Color.white.opacity(0.12))
                    .frame(height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    private func abbreviation(_ category: XPCategory) -> String {
        switch category {
        case .strength:   return "STR"
        case .endurance:  return "END"
        case .wisdom:     return "WIS"
        case .discipline: return "DIS"
        case .willpower:  return "WIL"
        case .vitality:   return "VIT"
        }
    }

    // MARK: - Detailed skill list (scrolls below the fold)

    private func statSheet(_ character: Character) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("SKILLS")
            ForEach(XPCategory.allCases, id: \.self) { category in
                categoryRow(category, progress: character.progress(for: category))
            }
        }
    }

    private func categoryRow(_ category: XPCategory, progress: CategoryProgress) -> some View {
        Button {
            selectedSkill = category
        } label: {
            HStack(spacing: 14) {
                Text(category.icon).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(category.rawValue)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("Lv \(progress.level)")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(category.color)
                    }
                    XPBar(progress: progress.progressToNext, color: category.color)
                    Text("\(progress.totalXP) XP")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                }
            }
            .padding(14)
            .solCard()
        }
        .buttonStyle(.plain)
    }

    private func customBars(_ character: Character) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("CUSTOM XP")
            ForEach(character.customXPBars) { bar in
                HStack(spacing: 14) {
                    Text("⭐️").font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(bar.name).font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            Spacer()
                            Text("Lv \(bar.level)").font(.system(size: 15, weight: .heavy)).foregroundStyle(Theme.gold)
                        }
                        XPBar(progress: bar.progressToNext, color: Theme.gold)
                    }
                }
                .padding(14)
                .solCard()
            }
        }
    }

    private func trackedStatsList(_ character: Character) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("TRACKED STATS")
            ForEach(character.trackedStats) { stat in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.definition.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(statSubtitle(stat))
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Text(lifetimeText(stat))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.gold)
                }
                .padding(14)
                .solCard()
            }
        }
    }

    private func statSubtitle(_ stat: TrackedStat) -> String {
        if stat.definition.type == .boolean {
            return "🔥 \(stat.currentStreak) day streak"
        }
        return "Today: \(formatted(stat.dailyValue))"
    }

    private func lifetimeText(_ stat: TrackedStat) -> String {
        if stat.definition.type == .boolean {
            return "\(Int(stat.lifetimeTotal)) days"
        }
        return "\(formatted(stat.lifetimeTotal)) \(stat.definition.unit ?? "")"
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Allow `XPCategory` to be used with .sheet(item:).
extension XPCategory: Identifiable {
    public var id: String { rawValue }
}
