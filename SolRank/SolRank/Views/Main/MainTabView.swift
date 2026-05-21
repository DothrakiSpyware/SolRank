import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 2 // Home is default

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
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
        .tint(.yellow)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Placeholder tab views

struct FeedView: View {
    var body: some View {
        NavigationStack {
            Text("Feed — Coming Soon")
                .foregroundStyle(.secondary)
                .navigationTitle("Feed")
        }
    }
}

struct CompeteView: View {
    var body: some View {
        NavigationStack {
            Text("Compete — Coming Soon")
                .foregroundStyle(.secondary)
                .navigationTitle("Compete")
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            Text("Home — Coming Soon")
                .foregroundStyle(.secondary)
                .navigationTitle("Home")
        }
    }
}

struct CharacterView: View {
    var body: some View {
        NavigationStack {
            Text("Character — Coming Soon")
                .foregroundStyle(.secondary)
                .navigationTitle("Character")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Button("Sign Out", role: .destructive) {
                    authVM.signOut()
                }
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    let authService = AuthService()
    let authVM = AuthViewModel(authService: authService)
    return MainTabView().environmentObject(authVM)
}
