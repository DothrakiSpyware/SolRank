import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var gameVM: GameViewModel

    @State private var step = 0
    @State private var name = ""
    @State private var appearance = Appearance.default
    @State private var selectedStatIDs: Set<String> = []
    @State private var isFinishing = false

    private let maxSelectable = 5

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                progressDots
                    .padding(.top, 16)

                TabView(selection: $step) {
                    CharacterCreationStep(name: $name, appearance: $appearance)
                        .tag(0)
                    StatSelectionStep(selected: $selectedStatIDs, maxSelectable: maxSelectable)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                footer
            }
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { index in
                Capsule()
                    .fill(index == step ? Theme.gold : Color.white.opacity(0.2))
                    .frame(width: index == step ? 24 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.3), value: step)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button(action: advance) {
                Text(step == 1 ? "Start Playing" : "Continue")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canAdvance ? Theme.goldGradient : LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canAdvance || isFinishing)

            if step > 0 {
                Button("Back") { withAnimation { step -= 1 } }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    private var canAdvance: Bool {
        switch step {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return !selectedStatIDs.isEmpty
        default: return true
        }
    }

    private func advance() {
        if step < 1 {
            withAnimation { step += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        guard let userID = authVM.appUser?.id else { return }
        isFinishing = true
        Task {
            await gameVM.createCharacter(
                userID: userID,
                name: name.trimmingCharacters(in: .whitespaces),
                appearance: appearance,
                selectedStatIDs: Array(selectedStatIDs)
            )
        }
    }
}
