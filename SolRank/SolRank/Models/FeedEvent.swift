import Foundation

/// The kinds of activity that can appear in the social feed.
/// Challenge/league cases exist so later sessions can post without a model change.
enum FeedEventType: String, Codable, CaseIterable {
    case statLogged
    case levelUp
    case challengeUpdate
    case challengeWon
    case leagueMilestone
    case streakMilestone
    case manual
}

/// A comment on a feed event.
struct FeedComment: Identifiable, Codable, Hashable {
    let id: String
    var authorID: String
    var authorUsername: String
    var text: String
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        authorID: String,
        authorUsername: String,
        text: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.authorID = authorID
        self.authorUsername = authorUsername
        self.text = text
        self.timestamp = timestamp
    }
}

/// A single entry in the social feed. Stored in the `feedEvents` Firestore collection.
struct FeedEvent: Identifiable, Codable, Equatable {
    let id: String
    var authorID: String
    var authorUsername: String
    var type: FeedEventType
    var message: String
    var xpGained: Int?
    var statCategory: XPCategory?
    var relatedID: String?
    var timestamp: Date
    var reactions: [String: Int]
    var comments: [FeedComment]

    init(
        id: String = UUID().uuidString,
        authorID: String,
        authorUsername: String,
        type: FeedEventType,
        message: String,
        xpGained: Int? = nil,
        statCategory: XPCategory? = nil,
        relatedID: String? = nil,
        timestamp: Date = Date(),
        reactions: [String: Int] = [:],
        comments: [FeedComment] = []
    ) {
        self.id = id
        self.authorID = authorID
        self.authorUsername = authorUsername
        self.type = type
        self.message = message
        self.xpGained = xpGained
        self.statCategory = statCategory
        self.relatedID = relatedID
        self.timestamp = timestamp
        self.reactions = reactions
        self.comments = comments
    }

    /// Robust decoding: tolerate documents missing the optional/collection fields.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        authorID = try c.decode(String.self, forKey: .authorID)
        authorUsername = try c.decodeIfPresent(String.self, forKey: .authorUsername) ?? "Adventurer"
        type = try c.decodeIfPresent(FeedEventType.self, forKey: .type) ?? .manual
        message = try c.decodeIfPresent(String.self, forKey: .message) ?? ""
        xpGained = try c.decodeIfPresent(Int.self, forKey: .xpGained)
        statCategory = try c.decodeIfPresent(XPCategory.self, forKey: .statCategory)
        relatedID = try c.decodeIfPresent(String.self, forKey: .relatedID)
        timestamp = try c.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        reactions = try c.decodeIfPresent([String: Int].self, forKey: .reactions) ?? [:]
        comments = try c.decodeIfPresent([FeedComment].self, forKey: .comments) ?? []
    }
}
