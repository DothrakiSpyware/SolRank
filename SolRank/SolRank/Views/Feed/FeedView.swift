import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel

    init(currentUserID: String, username: String, friendIDs: [String]) {
        _viewModel = StateObject(wrappedValue: FeedViewModel(
            currentUserID: currentUserID,
            currentUsername: username,
            friendIDs: friendIDs
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                content
            }
            .background(Theme.background)
            .navigationTitle("Feed")
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", icon: nil, color: Theme.gold, filter: .allFriends)
                chip(title: "Just Me", icon: nil, color: Theme.gold, filter: .justMe)
                ForEach(XPCategory.allCases, id: \.self) { category in
                    chip(title: category.rawValue, icon: category.icon, color: category.color, filter: .byCategory(category))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func chip(title: String, icon: String?, color: Color, filter: FeedFilter) -> some View {
        let isSelected = viewModel.filter == filter
        return Button {
            withAnimation(.spring(response: 0.3)) { viewModel.filter = filter }
        } label: {
            HStack(spacing: 5) {
                if let icon { Text(icon).font(.system(size: 13)) }
                Text(title).font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(isSelected ? .black : .white.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.feedEvents.isEmpty {
            Spacer()
            ProgressView().tint(Theme.gold)
            Spacer()
        } else if viewModel.filteredEvents.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredEvents) { event in
                        FeedEventRowView(viewModel: viewModel, event: event)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.filteredEvents.map(\.id))
            }
            .refreshable { await viewModel.refresh() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("📭").font(.system(size: 56))
            Text("No activity yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            Text("Log a stat or add friends to fill your feed.")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }
}
