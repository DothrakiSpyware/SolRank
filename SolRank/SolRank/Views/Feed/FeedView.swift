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
                scopeToggle
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                CategoryFilterBar(selected: $viewModel.categoryFilter)
                content
            }
            .background(Theme.background)
            .navigationTitle("Feed")
        }
    }

    // MARK: - Scope toggle

    private var scopeToggle: some View {
        HStack(spacing: 6) {
            scopeChip(title: "Just Me", scope: .justMe)
            scopeChip(title: "Friends", scope: .friends)
        }
        .padding(4)
        .background(Capsule().fill(Color.white.opacity(0.06)))
        .frame(maxWidth: 280)
    }

    private func scopeChip(title: String, scope: FeedScope) -> some View {
        let selected = viewModel.scope == scope
        return Button {
            withAnimation(.spring(response: 0.25)) { viewModel.scope = scope }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(selected ? .black : .white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Capsule().fill(selected ? Theme.gold : Color.clear))
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
                .padding(.top, 6)
                .padding(.bottom, 12)
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
