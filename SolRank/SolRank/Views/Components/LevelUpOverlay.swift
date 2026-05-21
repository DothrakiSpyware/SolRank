import SwiftUI

/// Full-screen Duolingo-style celebration shown when a level-up occurs.
struct LevelUpOverlay: View {
    let event: LevelUpEvent
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                Text(event.icon)
                    .font(.system(size: 90))
                    .scaleEffect(appeared ? 1 : 0.4)
                    .rotationEffect(.degrees(appeared ? 0 : -20))

                Text("LEVEL UP!")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.goldGradient)

                Text("\(event.title) reached Level \(event.newLevel)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Button(action: onDismiss) {
                    Text("Nice!")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Theme.goldGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 12)
                .padding(.horizontal, 40)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true }
        }
    }
}
