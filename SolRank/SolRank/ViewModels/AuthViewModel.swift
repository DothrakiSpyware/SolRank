import Foundation
import AuthenticationServices
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var authState: AuthService.AuthState = .loading
    @Published var errorMessage: String?
    @Published var isLoading = false

    var appUser: AppUser? { authService.appUser }

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService) {
        self.authService = authService
        authService.$authState
            .receive(on: DispatchQueue.main)
            .assign(to: &$authState)
    }

    // MARK: - Sign in with Apple

    func prepareAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        authService.prepareAppleSignInRequest(request)
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        await performAuth { try await self.authService.handleAppleSignInResult(result) }
    }

    // MARK: - Sign in with Google

    func signInWithGoogle() async {
        await performAuth { try await self.authService.signInWithGoogle() }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() { errorMessage = nil }

    // MARK: - Helpers

    private func performAuth(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
