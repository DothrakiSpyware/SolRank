import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var gameVM: GameViewModel
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var selectedTab = 2 // Home is default

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(
                currentUserID: authVM.appUser?.id ?? "",
                username: gameVM.character?.name ?? authVM.appUser?.displayName ?? "Me",
                friendIDs: authVM.appUser?.friendIDs ?? []
            )
            .tabItem { Label("Feed", systemImage: "person.2.fill") }
            .tag(0)

            CompeteView()
                .tabItem { Label("Compete", systemImage: "trophy.fill") }
                .tag(1)

            HomeView()
                .tabItem { Label("Home", systemImage: "bolt.fill") }
                .tag(2)

            CharacterView()
                .tabItem { Label("Character", systemImage: "person.fill") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(Theme.gold)
        .preferredColorScheme(.dark)
        .overlay {
            if let event = gameVM.levelUpEvent {
                LevelUpOverlay(event: event) { gameVM.levelUpEvent = nil }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: gameVM.levelUpEvent)
    }
}

// MARK: - Placeholder tab views (built out in later sessions)

struct CompeteView: View {
    var body: some View {
        NavigationStack {
            Text("Compete — Coming Soon")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.background)
                .navigationTitle("Compete")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var gameVM: GameViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Name", value: gameVM.character?.name ?? authVM.appUser?.displayName ?? "—")
                    if let email = authVM.appUser?.email {
                        LabeledContent("Email", value: email)
                    }
                    LabeledContent("Points", value: "\(authVM.appUser?.pointsBalance ?? 0)")
                }
                Section {
                    Button("Sign Out", role: .destructive) {
                        authVM.signOut()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Profile")
        }
    }
}
