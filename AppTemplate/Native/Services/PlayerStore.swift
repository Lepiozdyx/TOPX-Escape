import SwiftUI

@MainActor
final class PlayerStore: ObservableObject {
    @Published private(set) var save: PlayerSave
    @Published private(set) var storageMessage: String?
    private let key = "footballx.tactics.save.v2"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key), let stored = try? JSONDecoder().decode(PlayerSave.self, from: data), stored.version == 2 {
            save = stored
        } else {
            save = PlayerSave()
            if defaults.data(forKey: key) != nil { storageMessage = "Your save could not be read. A fresh profile is ready." }
        }
        if grantChapterRewards() > 0 { persist() }
    }

    var stars: Int { save.records.values.reduce(0) { $0 + $1.stars } }
    var campaignWins: Int { StageCatalog.campaign.filter { save.records[$0.id] != nil }.count }
    var challengesUnlocked: Bool { campaignWins == StageCatalog.campaign.count }
    var nextLevel: StageLayout { StageCatalog.campaign.first { save.records[$0.id] == nil } ?? StageCatalog.campaign[15] }
    var hasUnfinishedMatch: Bool { save.match?.snapshot.outcome == .active }

    func isUnlocked(_ level: StageLayout) -> Bool {
        if level.isChallenge { return challengesUnlocked }
        return level.number == 1 || save.records["campaign-\(level.number - 1)"] != nil
    }

    func isChapterComplete(_ chapter: Int) -> Bool {
        let levels = StageCatalog.campaign.filter { $0.chapter == chapter }
        return !levels.isEmpty && levels.allSatisfy { save.records[$0.id] != nil }
    }

    @discardableResult
    func begin(_ level: StageLayout) -> SavedMatch {
        let current = StageCatalog.level(level.id) ?? level
        let match = SavedMatch(levelID: current.id, snapshot: current.initial, scenarioRevision: current.revision)
        save.match = match
        persist()
        return match
    }

    @discardableResult
    func record(_ match: SavedMatch, level: StageLayout) -> SavedMatch {
        var completed = match
        if match.snapshot.outcome == .won {
            let stars = level.stars(for: match.snapshot.moves)
            let previous = save.records[level.id]
            let gained = max(0, stars - (previous?.stars ?? 0)) * RewardRules.coinsPerStar
            save.records[level.id] = LevelRecord(stars: max(stars, previous?.stars ?? 0), bestMoves: min(match.snapshot.moves, previous?.bestMoves ?? Int.max))
            let chapterBonus = grantChapterRewards()
            save.coins += gained
            completed.starsEarned = stars
            completed.coinsEarned = gained + chapterBonus
            completed.chapterBonusEarned = chapterBonus
        }
        save.match = completed
        persist()
        return completed
    }

    func saveAttempt(_ match: SavedMatch) { save.match = match; persist() }
    func clearAttempt() { save.match = nil; persist() }
    func updateSettings(_ update: (inout PlayerSettings) -> Void) { update(&save.settings); persist() }
    func dismissStorageMessage() { storageMessage = nil }

    private func grantChapterRewards() -> Int {
        let newlyCompleted = StageCatalog.chapters.filter {
            !save.rewardedChapters.contains($0.id) && isChapterComplete($0.id)
        }
        guard !newlyCompleted.isEmpty else { return 0 }
        let bonus = newlyCompleted.count * RewardRules.chapterCompletion
        save.rewardedChapters.formUnion(newlyCompleted.map(\.id))
        save.coins += bonus
        return bonus
    }

    func owns(_ item: CosmeticItem) -> Bool {
        item.kind == .field ? save.ownedFields.contains(item.id) : save.ownedBalls.contains(item.id)
    }
    func isSelected(_ item: CosmeticItem) -> Bool {
        item.kind == .field ? save.selectedField == item.id : save.selectedBall == item.id
    }
    @discardableResult
    func selectOrBuy(_ item: CosmeticItem) -> Bool {
        if !owns(item) {
            guard save.coins >= item.price else { return false }
            save.coins -= item.price
            if item.kind == .field { save.ownedFields.insert(item.id) } else { save.ownedBalls.insert(item.id) }
        }
        if item.kind == .field { save.selectedField = item.id } else { save.selectedBall = item.id }
        persist()
        return true
    }

    private func persist() {
        do { defaults.set(try JSONEncoder().encode(save), forKey: key) }
        catch { storageMessage = "We couldn't save this change. Keep the game open and try again." }
    }
}
