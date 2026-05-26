import SwiftUI

/// Full-width slider row for boolean check-in stats.
/// User drags a thumb left (no) or right (yes); a 60% threshold registers the action.
/// After logging, the slider locks into a dormant state for the rest of the day.
struct DailyCheckInSlider: View {
    let stat: TrackedStat
    let onLogYes: () -> Void
    let onLogNo: () -> Void
    let onChangeEmoji: (String) -> Void

    @State private var dragX: CGFloat = 0
    @State private var locked: Bool = false
    @State private var pulse: Bool = false
    @State private var showEmojiPicker = false

    private let trackHeight: CGFloat = 56
    private let thumbSize: CGFloat = 44
    private let curatedEmojis = ["🌟", "💪", "🔥", "✅", "🎯", "🏆", "🧘", "💚"]

    var body: some View {
        Group {
            if stat.isCompletedToday {
                dormantYes
            } else if stat.isLoggedNoToday {
                dormantNo
            } else {
                active
            }
        }
        .frame(height: trackHeight)
        .onAppear { locked = stat.isBooleanLockedToday }
        .sheet(isPresented: $showEmojiPicker) { emojiPickerSheet }
    }

    // MARK: - Active (draggable) state

    private var active: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let usable = width - thumbSize
            let center = usable / 2
            let progress = max(-1, min(1, dragX / center))  // -1...+1

            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule().stroke(
                            Color.red.opacity(pulse ? 0.7 : 0.35),
                            lineWidth: 1.5
                        )
                    )

                // Drag-tint overlay
                Capsule()
                    .fill(
                        progress >= 0
                            ? Color.green.opacity(0.18 * Double(abs(progress)))
                            : Color.red.opacity(0.18 * Double(abs(progress)))
                    )
                    .allowsHitTesting(false)

                // Labels (sit behind/above the track ends)
                HStack {
                    Text("👎 No")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.gray)
                        .padding(.leading, thumbSize + 6)
                    Spacer()
                    Text(stat.definition.name)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                    Spacer()
                    Text("Yes 👍")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.gray)
                        .padding(.trailing, thumbSize + 6)
                }
                .padding(.horizontal, 8)
                .allowsHitTesting(false)

                // Pulsing red dot (outstanding check-in)
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulse ? 1.4 : 1.0)
                    .opacity(pulse ? 0.6 : 1.0)
                    .position(x: 14, y: trackHeight / 2)
                    .animation(
                        .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                        value: pulse
                    )

                // Thumb
                ZStack {
                    Circle()
                        .fill(progress >= 0 ? Color.green : Color.red)
                        .opacity(0.5 + 0.5 * abs(Double(progress)))
                    Image(systemName: progress >= 0 ? "arrow.right" : "arrow.left")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(.white)
                        .opacity(abs(Double(progress)) > 0.15 ? 1.0 : 0.0)
                }
                .frame(width: thumbSize, height: thumbSize)
                .offset(x: center + dragX)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragX = max(-center, min(center, value.translation.width))
                        }
                        .onEnded { _ in
                            let threshold = center * 0.6
                            if dragX >= threshold {
                                commitYes()
                            } else if dragX <= -threshold {
                                commitNo()
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    dragX = 0
                                }
                            }
                        }
                )
            }
            .onAppear { pulse = true }
        }
    }

    private func commitYes() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        onLogYes()
        withAnimation(.spring()) { dragX = 0 }
    }

    private func commitNo() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        onLogNo()
        withAnimation(.spring()) { dragX = 0 }
    }

    // MARK: - Dormant YES

    private var dormantYes: some View {
        HStack(spacing: 10) {
            Text(stat.definition.name)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
            Text("✅")
                .font(.system(size: 18))
            Text(stat.celebrationEmoji)
                .font(.system(size: 22))
            Spacer()
            if stat.currentStreak > 0 {
                Text("🔥 \(stat.currentStreak)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.gold)
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Capsule().fill(Color.green.opacity(0.22))
        )
        .overlay(Capsule().stroke(Color.green.opacity(0.45), lineWidth: 1))
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: 0.5) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showEmojiPicker = true
        }
    }

    // MARK: - Dormant NO

    private var dormantNo: some View {
        HStack(spacing: 10) {
            Text(stat.definition.name)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white.opacity(0.85))
            Text("— logged")
                .font(.system(size: 13))
                .foregroundStyle(.gray)
            Text("😔")
                .font(.system(size: 18))
            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Capsule().fill(Color.orange.opacity(0.18))
        )
        .overlay(Capsule().stroke(Color.red.opacity(0.35), lineWidth: 1))
    }

    // MARK: - Emoji picker

    private var emojiPickerSheet: some View {
        VStack(spacing: 18) {
            Text("Celebration emoji")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 24)
            Text("Shown when you log \(stat.definition.name) ✅")
                .font(.system(size: 13))
                .foregroundStyle(.gray)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(curatedEmojis, id: \.self) { emoji in
                    Button {
                        onChangeEmoji(emoji)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showEmojiPicker = false
                    } label: {
                        Text(emoji)
                            .font(.system(size: 30))
                            .frame(width: 56, height: 56)
                            .background(
                                Circle().fill(
                                    emoji == stat.celebrationEmoji
                                        ? Theme.gold.opacity(0.3)
                                        : Color.white.opacity(0.08)
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .presentationDetents([.height(320)])
    }
}
