import Foundation

struct AppUser: Identifiable, Codable {
    let id: String
    var displayName: String
    var email: String?
    var photoURL: URL?
    var pointsBalance: Int
    var characterID: String?
    var friendIDs: [String]
    var createdAt: Date

    init(id: String, displayName: String, email: String? = nil, photoURL: URL? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.pointsBalance = 100
        self.characterID = nil
        self.friendIDs = []
        self.createdAt = Date()
    }
}
