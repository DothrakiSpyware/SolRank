import Foundation
import FirebaseFirestore

/// Persists the user's Character document to Firestore.
/// The whole character (appearance, XP, tracked stats, recent entries) lives in
/// a single document keyed by the user id — sufficient for the beta friend group.
@MainActor
final class GameService {
    private let db = Firestore.firestore()

    private func characterRef(_ id: String) -> DocumentReference {
        db.collection(Constants.Firestore.characters).document(id)
    }

    /// Loads the character for a user, or nil if none exists yet.
    func loadCharacter(userID: String) async throws -> Character? {
        let snapshot = try await characterRef(userID).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: Character.self)
    }

    /// Creates or overwrites the character document.
    func saveCharacter(_ character: Character) async throws {
        try characterRef(character.id).setData(from: character, merge: true)
    }
}
