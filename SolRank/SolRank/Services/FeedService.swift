import Foundation
import FirebaseFirestore

/// Reads and writes social feed events in Firestore.
@MainActor
final class FeedService {
    private let db = Firestore.firestore()
    private var collection: CollectionReference {
        db.collection(Constants.Firestore.feedEvents)
    }

    // MARK: - Writing

    func postEvent(_ event: FeedEvent) async throws {
        try collection.document(event.id).setData(from: event)
    }

    func addReaction(eventID: String, emoji: String) async throws {
        try await collection.document(eventID).updateData([
            FieldPath(["reactions", emoji]): FieldValue.increment(Int64(1))
        ])
    }

    func addComment(eventID: String, comment: FeedComment) async throws {
        let encoded = try Firestore.Encoder().encode(comment)
        try await collection.document(eventID).updateData([
            "comments": FieldValue.arrayUnion([encoded])
        ])
    }

    // MARK: - Reading

    /// Fetches recent feed events authored by any of `friendIDs`.
    /// Firestore caps `in` queries at 10 values, so we batch and merge client-side.
    func fetchFeedForUser(friendIDs: [String], limit: Int = 25) async throws -> [FeedEvent] {
        let ids = Array(Set(friendIDs))
        guard !ids.isEmpty else { return [] }

        var merged: [FeedEvent] = []
        for batch in ids.chunked(into: 10) {
            let snapshot = try await collection
                .whereField("authorID", in: batch)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()
            merged.append(contentsOf: snapshot.documents.compactMap { try? $0.data(as: FeedEvent.self) })
        }
        return Array(merged.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }

    /// Live listener for the feed. Beta friend groups are small, so we listen on
    /// the first 10 author IDs (Firestore's `in` limit). Returns the registration
    /// so the caller can detach it.
    func attachRealtimeListener(
        friendIDs: [String],
        limit: Int = 25,
        onChange: @escaping ([FeedEvent]) -> Void
    ) -> ListenerRegistration {
        let ids = Array(Array(Set(friendIDs)).prefix(10))
        let queryIDs = ids.isEmpty ? ["__none__"] : ids

        return collection
            .whereField("authorID", in: queryIDs)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .addSnapshotListener { snapshot, _ in
                // On error `snapshot` is nil — keep the caller's last data untouched.
                guard let snapshot else { return }
                let events = snapshot.documents.compactMap { try? $0.data(as: FeedEvent.self) }
                onChange(events)
            }
    }
}

extension Array {
    /// Splits the array into chunks of at most `size` elements.
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
