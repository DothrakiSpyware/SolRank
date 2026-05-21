import SwiftUI

struct StatSelectionStep: View {
    @Binding var selected: Set<String>
    let maxSelectable: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                ForEach(PreloadedStats.grouped(), id: \.category) { group in
                    if !group.stats.isEmpty {
                        categorySection(group.category, stats: group.stats)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Choose Your Stats")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Pick \(maxSelectable) or fewer to start. Add more anytime.")
                .font(.system(size: 15))
                .foregroundStyle(.gray)
            Text("\(selected.count) / \(maxSelectable) selected")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.gold)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func categorySection(_ category: Constants.XPCategory, stats: [StatDefinition]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(category.icon)
                Text(category.rawValue.uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(category.color)
            }
            ForEach(stats) { stat in
                statRow(stat)
            }
        }
    }

    private func statRow(_ stat: StatDefinition) -> some View {
        let isSelected = selected.contains(stat.id)
        let atLimit = selected.count >= maxSelectable && !isSelected
        return Button {
            toggle(stat.id, isSelected: isSelected)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(stat.type.displayName + (stat.unit.map { " · \($0)" } ?? ""))
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Theme.gold : Color.white.opacity(0.25))
            }
            .padding(14)
            .solCard()
            .opacity(atLimit ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(atLimit)
    }

    private func toggle(_ id: String, isSelected: Bool) {
        if isSelected {
            selected.remove(id)
        } else if selected.count < maxSelectable {
            selected.insert(id)
        }
    }
}
