import SwiftUI

struct CharacterView: View {
    @EnvironmentObject private var gameVM: GameViewModel
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if let character = gameVM.character {
                    VStack(spacing: 24) {
                        heroHeader(character)
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
        }
    }

    private func heroHeader(_ character: Character) -> some View {
        VStack(spacing: 12) {
            CharacterSprite(appearance: character.appearance, size: 120)
            Text(character.name)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            HStack(spacing: 16) {
                badge(label: "LEVEL", value: "\(character.overallLevel)", color: Theme.gold)
                badge(label: "POINTS", value: "\(authVM.appUser?.pointsBalance ?? 0)", color: Theme.gold)
            }
        }
        .padding(.top, 12)
    }

    private func badge(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.gray)
        }
        .frame(minWidth: 80)
        .padding(.vertical, 10)
        .solCard()
    }

    private func statSheet(_ character: Character) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("SKILLS")
            ForEach(Constants.XPCategory.allCases, id: \.self) { category in
                categoryRow(category, progress: character.progress(for: category))
            }
        }
    }

    private func categoryRow(_ category: Constants.XPCategory, progress: CategoryProgress) -> some View {
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
