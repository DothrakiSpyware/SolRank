import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var gameVM: GameViewModel

    var body: some View {
        Group {
            switch authVM.authState {
            case .loading:
                SplashView()
            case .unauthenticated:
                SignInView()
            case .authenticated:
                authenticatedFlow
            }
        }
        .preferredColorScheme(.dark)
        // Reload the character whenever the signed-in user changes.
        .task(id: authVM.appUser?.id) {
            guard let userID = authVM.appUser?.id else { return }
            await gameVM.load(userID: userID)
        }
    }

    @ViewBuilder
    private var authenticatedFlow: some View {
        if gameVM.isLoading {
            SplashView()
        } else if gameVM.needsOnboarding {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("⚔️")
                    .font(.system(size: 72))
                Text("SolRank")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                ProgressView()
                    .tint(.yellow)
                    .padding(.top, 8)
            }
        }
    }
}
