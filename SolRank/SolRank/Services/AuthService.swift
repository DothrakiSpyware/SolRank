import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import GoogleSignIn

@MainActor
final class AuthService: NSObject, ObservableObject {
    @Published private(set) var firebaseUser: User?
    @Published private(set) var appUser: AppUser?
    @Published private(set) var authState: AuthState = .loading

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private(set) var currentNonce: String?

    override init() {
        super.init()
        attachAuthListener()
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Auth State

    enum AuthState {
        case loading
        case authenticated
        case unauthenticated
    }

    private func attachAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                self.firebaseUser = user
                if let user {
                    await self.loadOrCreateAppUser(for: user)
                    self.authState = .authenticated
                } else {
                    self.appUser = nil
                    self.authState = .unauthenticated
                }
            }
        }
    }

    // MARK: - Sign in with Apple (two-step: prepare + handle)

    /// Sets the nonce on the Apple request and stores it for later verification.
    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// Processes the authorization result returned by SignInWithAppleButton.
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async throws {
        let authorization = try result.get()

        guard
            let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = appleCredential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8),
            let rawNonce = currentNonce
        else {
            throw AuthError.invalidCredential
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: appleCredential.fullName
        )

        try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Sign in with Google

    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.configurationError
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        else {
            throw AuthError.noPresentingViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidCredential
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Sign Out

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }

    // MARK: - Firestore user sync

    /// Re-reads the current user's document to refresh cached fields like points.
    func reloadAppUser() async {
        guard let firebaseUser else { return }
        await loadOrCreateAppUser(for: firebaseUser)
    }

    private func loadOrCreateAppUser(for firebaseUser: User) async {
        let db = Firestore.firestore()
        let ref = db.collection(Constants.Firestore.users).document(firebaseUser.uid)

        do {
            let snapshot = try await ref.getDocument()
            if snapshot.exists, let user = try? snapshot.data(as: AppUser.self) {
                appUser = user
            } else {
                let newUser = AppUser(
                    id: firebaseUser.uid,
                    displayName: firebaseUser.displayName ?? "Adventurer",
                    email: firebaseUser.email,
                    photoURL: firebaseUser.photoURL
                )
                try? ref.setData(from: newUser)
                appUser = newUser
            }
        } catch {
            appUser = AppUser(
                id: firebaseUser.uid,
                displayName: firebaseUser.displayName ?? "Adventurer",
                email: firebaseUser.email,
                photoURL: firebaseUser.photoURL
            )
        }
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        guard SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes) == errSecSuccess else {
            fatalError("Unable to generate secure nonce")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredential
    case configurationError
    case noPresentingViewController

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid credentials. Please try again."
        case .configurationError: return "App configuration error. Contact support."
        case .noPresentingViewController: return "Unable to present sign-in screen."
        }
    }
}
