import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        switch authVM.authState {
        case .loading:
            SplashView()
        case .unauthenticated:
            SignInView()
        case .authenticated:
            MainTabView()
        }
    }
}

private struct SplashView: View {
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
            }
        }
    }
}
