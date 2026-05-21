import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct SolRankApp: App {
    @StateObject private var authVM: AuthViewModel

    init() {
        FirebaseApp.configure()
        let service = AuthService()
        _authVM = StateObject(wrappedValue: AuthViewModel(authService: service))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .onOpenURL { url in
                    // Required for Google Sign-In OAuth callback
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
