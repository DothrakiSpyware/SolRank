import Foundation
import SwiftUI
import FirebaseFirestore

/// Active filter applied to the feed.
enum FeedFilter: Equatable, Hashable {
    case allFriends
    case justMe
    case byCategory(XPCategory)
}

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var feedEvents: [FeedEvent] = []
    @Published var isLoading = true
    @Published var filter: FeedFilter = .allFriends

    private let service: FeedService
    private let currentUserID: String
    private let currentUsername: String
    private let friendIDs: [String]
    private var listener: ListenerRegistration?

    init(
        currentUserID: String,
        currentUsername: String,
        friendIDs: [String],
        service: FeedService = FeedService()
    ) {
        self.currentUserID = currentUserID
        self.currentUsername = currentUsername
        self.friendIDs = friendIDs
        self.service = service
        start()
    }

    deinit {
        listener?.remove()
    }

    /// Friends plus the user themselves, so they see their own activity.
    private var audienceIDs: [String] {
        Array(Set(friendIDs + [currentUserID]))
    }

    // MARK: - Lifecycle

    private func start() {
        isLoading = true

        // Initial one-shot fetch as a fallback if the listener is slow/offline.
        Task {
            if let events = try? await service.fetchFeedForUser(friendIDs: audienceIDs, limit: 25) {
                if feedEvents.isEmpty { feedEvents = events }
            }
            isLoading = false
        }

        listener = service.attachRealtimeListener(friendIDs: audienceIDs) { [weak self] events in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.feedEvents = events
                self.isLoading = false
            }
        }
    }

    func refresh() async {
        if let events = try? await service.fetchFeedForUser(friendIDs: audienceIDs, limit: 25) {
            feedEvents = events
        }
        isLoading = false
    }

    // MARK: - Filtering

    var filteredEvents: [FeedEvent] {
        switch filter {
        case .allFriends:
            return feedEvents
        case .justMe:
            return feedEvents.filter { $0.authorID == currentUserID }
        case .byCategory(let category):
            return feedEvents.filter { $0.statCategory == category }
        }
    }

    // MARK: - Interactions (optimistic local update + remote write)

    func addReaction(to event: FeedEvent, emoji: String) {
        if let index = feedEvents.firstIndex(where: { $0.id == event.id }) {
            feedEvents[index].reactions[emoji, default: 0] += 1
        }
        Task { try? await service.addReaction(eventID: event.id, emoji: emoji) }
    }

    func submitComment(on event: FeedEvent, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let comment = FeedComment(
            authorID: currentUserID,
            authorUsername: currentUsername,
            text: trimmed
        )
        if let index = feedEvents.firstIndex(where: { $0.id == event.id }) {
            feedEvents[index].comments.append(comment)
        }
        Task { try? await service.addComment(eventID: event.id, comment: comment) }
    }
}
