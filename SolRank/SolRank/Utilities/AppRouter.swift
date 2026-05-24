import SwiftUI
import Combine

/// Shared navigation state so detail screens can switch the main tab
/// (e.g. "Log Progress" jumping to Home).
@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Int { case feed = 0, compete = 1, home = 2, character = 3, profile = 4 }

    @Published var selectedTab: Int = Tab.home.rawValue

    func go(to tab: Tab) { selectedTab = tab.rawValue }
}
