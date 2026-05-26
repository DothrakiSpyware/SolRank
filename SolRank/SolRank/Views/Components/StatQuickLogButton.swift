import SwiftUI

/// Square card used in the home screen 2-column grid for numeric stats.
/// Tap the body to log the current increment with a satisfying spring/scale animation.
/// Use the inline stepper to adjust the increment for this session (and persist it).
struct StatQuickLogButton: View {
    let stat: TrackedStat
    let onLog: (Double) -> Void

    @State private var localIncrement: Double
    @State private var showManualEntry = false
    @State private var manualValue = ""
    @State private var scale: CGFloat = 1.0

    init(
        stat: TrackedStat,
        onLog: @escaping (Double) -> Void
    ) {
        self.stat = stat
        self.onLog = onLog
        _localIncrement = State(initialValue: stat.increment)
    }

    private var color: Color { stat.definition.category?.color ?? Theme.gold }

    var body: some View {
        ZStack {
            // Card body — tap to log
            Button(action: tapLog) {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Text(stat.definition.category?.icon ?? "⭐️")
                            .font(.system(size: 18))
                        Text(stat.definition.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                    }
                    Text("+\(formatted(localIncrement))")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(color)
                        .clipShape(Capsule())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: 0)
                    Text(formatted(stat.dailyValue))
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    if let unit = stat.definition.unit, !unit.isEmpty {
                        Text(unit.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray)
                    }
                    stepper
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .frame(height: 168)
                .solCard()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
                .scaleEffect(scale)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                showManualEntry = true
            })
        }
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

    // MARK: - Stepper

    private var stepper: some View {
        HStack(spacing: 0) {
            stepperButton(symbol: "minus") {
                localIncrement = max(1, localIncrement - stepSize())
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            Text("+\(formatted(localIncrement))")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
            stepperButton(symbol: "plus") {
                localIncrement += stepSize()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .frame(height: 30)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    private func stepperButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(color)
                .frame(width: 34, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Choose a sensible step granularity based on current size.
    private func stepSize() -> Double {
        if localIncrement >= 50 { return 10 }
        if localIncrement >= 10 { return 5 }
        return 1
    }

    // MARK: - Tap log

    private func tapLog() {
        onLog(localIncrement)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { scale = 1.07 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { scale = 1.0 }
        }
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
