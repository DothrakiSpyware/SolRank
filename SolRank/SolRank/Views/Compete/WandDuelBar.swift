import SwiftUI

/// Head-to-head duel bar for 2-participant challenges (spec §9).
/// A glowing orb sits on a split bar; its position reflects the share of
/// total progress. Animates with a spring when the live values change.
struct WandDuelBar: View {
    let leftName: String
    let leftValue: Double
    let rightName: String
    let rightValue: Double
    var leftColor: Color = Color(hex: "#458CF2")   // blue
    var rightColor: Color = Color(hex: "#E54345")  // red

    /// Fraction of total progress held by the left participant (0...1).
    private var leftFraction: CGFloat {
        let total = leftValue + rightValue
        guard total > 0 else { return 0.5 }
        return CGFloat(leftValue / total)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                duelLabel(name: leftName, value: leftValue, color: leftColor, alignment: .leading)
                Spacer()
                duelLabel(name: rightName, value: rightValue, color: rightColor, alignment: .trailing)
            }

            GeometryReader { geo in
                let width = geo.size.width
                let orbX = max(18, min(width - 18, leftFraction * width))

                ZStack(alignment: .leading) {
                    // Split track
                    HStack(spacing: 0) {
                        leftColor.opacity(0.55)
                        rightColor.opacity(0.55)
                    }
                    .clipShape(Capsule())

                    // Center seam
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 2)
                        .position(x: width / 2, y: 18)

                    // Glowing orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, leftFraction >= 0.5 ? leftColor : rightColor],
                                center: .center,
                                startRadius: 1,
                                endRadius: 18
                            )
                        )
                        .frame(width: 30, height: 30)
                        .shadow(color: (leftFraction >= 0.5 ? leftColor : rightColor).opacity(0.9), radius: 10)
                        .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 2))
                        .position(x: orbX, y: 18)
                }
                .frame(height: 36)
            }
            .frame(height: 36)
            .animation(.spring(response: 0.55, dampingFraction: 0.7), value: leftFraction)
        }
    }

    private func duelLabel(name: String, value: Double, color: Color, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(name)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
            Text(formatValue(value))
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func formatValue(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

/// Ranked list shown for challenges with more than 2 participants.
struct RankedProgressList: View {
    let challenge: Challenge

    private var maxValue: Double {
        max(challenge.ranking.first?.value ?? 0, 1)
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(challenge.ranking.enumerated()), id: \.offset) { index, entry in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(index == 0 ? Theme.gold : .gray)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(challenge.name(for: entry.id))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text(format(entry.value))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(index == 0 ? Theme.gold : .white)
                        }
                        XPBar(progress: entry.value / maxValue, color: index == 0 ? Theme.gold : .gray)
                    }
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: challenge.totalProgress)
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
