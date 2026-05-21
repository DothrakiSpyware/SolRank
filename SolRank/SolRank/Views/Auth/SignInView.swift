import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                heroSection
                Spacer()
                authButtons
            }

            if authVM.isLoading {
                loadingOverlay
            }
        }
        .alert("Sign In Error", isPresented: Binding(
            get: { authVM.errorMessage != nil },
            set: { if !$0 { authVM.clearError() } }
        )) {
            Button("OK") { authVM.clearError() }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var heroSection: some View {
        VStack(spacing: 16) {
            Text("⚔️")
                .font(.system(size: 80))

            Text("SolRank")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, Color(red: 1, green: 0.55, blue: 0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Your life. Your stats. Your rank.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.gray)
        }
        .padding(.bottom, 60)
    }

    private var authButtons: some View {
        VStack(spacing: 12) {
            // Sign in with Apple — uses native button; result is piped through AuthViewModel
            SignInWithAppleButton(.signIn) { request in
                authVM.prepareAppleSignIn(request)
            } onCompletion: { result in
                Task { await authVM.handleAppleSignIn(result: result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Sign in with Google — custom branded button
            Button {
                Task { await authVM.signInWithGoogle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 22))
                    Text("Sign in with Google")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(white: 0.18))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 52)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            ProgressView()
                .tint(.white)
                .scaleEffect(1.6)
        }
    }
}

#Preview {
    let service = AuthService()
    return SignInView()
        .environmentObject(AuthViewModel(authService: service))
}
