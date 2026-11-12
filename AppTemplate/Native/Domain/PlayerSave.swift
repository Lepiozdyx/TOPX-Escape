import Foundation

enum RewardRules {
    static let coinsPerStar = 10
    static let chapterCompletion = 80
}

struct LevelRecord: Codable {
    var stars: Int
    var bestMoves: Int
}

struct PlayerSettings: Codable, Equatable {
    var music = true
    var effects = true
    var haptics = true
}

struct PlayerSave: Codable {
    var version = 2
    var coins = 0
    var records: [String: LevelRecord] = [:]
    var rewardedChapters: Set<Int> = []
    var ownedFields: Set<Int> = [0]
    var ownedBalls: Set<Int> = [0]
    var selectedField = 0
    var selectedBall = 0
    var settings = PlayerSettings()
    var match: SavedMatch?

    private enum CodingKeys: String, CodingKey {
        case version, coins, records, rewardedChapters, ownedFields, ownedBalls
        case selectedField, selectedBall, settings, match
    }

    init() {}

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decode(Int.self, forKey: .version)
        coins = try values.decode(Int.self, forKey: .coins)
        records = try values.decode([String: LevelRecord].self, forKey: .records)
        rewardedChapters = try values.decodeIfPresent(Set<Int>.self, forKey: .rewardedChapters) ?? []
        ownedFields = try values.decode(Set<Int>.self, forKey: .ownedFields)
        ownedBalls = try values.decode(Set<Int>.self, forKey: .ownedBalls)
        selectedField = try values.decode(Int.self, forKey: .selectedField)
        selectedBall = try values.decode(Int.self, forKey: .selectedBall)
        settings = try values.decode(PlayerSettings.self, forKey: .settings)
        match = try values.decodeIfPresent(SavedMatch.self, forKey: .match)
    }
}
