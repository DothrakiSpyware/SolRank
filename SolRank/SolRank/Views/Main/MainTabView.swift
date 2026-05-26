import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var gameVM: GameViewModel
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
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

            SettingsView()
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
