import SwiftUI

/// Compact horizontal pill row of category emoji chips (~36pt tall).
/// Combines with the feed's scope toggle for two-dimensional filtering.
struct CategoryFilterBar: View {
    @Binding var selected: XPCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip(label: "All", emoji: nil, isSelected: selected == nil) {
                    selected = nil
                }
                ForEach(XPCategory.allCases, id: \.self) { category in
                    chip(
                        label: nil,
                        emoji: category.icon,
                        isSelected: selected == category
                    ) {
                        selected = category
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 36)
    }

    private func chip(
        label: String?,
        emoji: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { action() }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 4) {
                if let emoji { Text(emoji).font(.system(size: 14)) }
                if let label {
                    Text(label).font(.system(size: 12, weight: .bold))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(
                    isSelected ? Theme.gold : Color.white.opacity(0.08)
                )
            )
            .foregroundStyle(isSelected ? .black : .white.opacity(0.85))
        }
        .buttonStyle(.plain)
    }
}
