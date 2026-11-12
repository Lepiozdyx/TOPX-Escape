import Foundation

struct PitchPosition: Hashable, Codable, Identifiable {
    let row: Int
    let column: Int
    var id: Int { row * PitchRules.columns + column }
    var isInside: Bool { (0..<PitchRules.rows).contains(row) && (0..<PitchRules.columns).contains(column) }
    var isBoundary: Bool { row == 0 || row == PitchRules.rows - 1 || column == 0 || column == PitchRules.columns - 1 }

    func neighbor(_ direction: Int) -> PitchPosition {
        let even = row.isMultiple(of: 2)
        let offsets = [(-1, even ? -1 : 0), (-1, even ? 0 : 1), (0, 1), (1, even ? 0 : 1), (1, even ? -1 : 0), (0, -1)]
        let offset = offsets[direction]
        return PitchPosition(row: row + offset.0, column: column + offset.1)
    }
    var neighbors: [PitchPosition] { (0..<6).map(neighbor).filter(\.isInside) }
}

enum PitchRules {
    static let rows = 11
    static let columns = 7
    static let positions = (0..<rows).flatMap { row in (0..<columns).map { PitchPosition(row: row, column: $0) } }
}

enum TacticalTool: String, Codable, CaseIterable, Identifiable {
    case barrier, wall, relocate
    var id: String { rawValue }
    var title: String {
        switch self { case .barrier: return "Barrier"; case .wall: return "Double wall"; case .relocate: return "Relocate" }
    }
    var symbol: String {
        switch self { case .barrier: return "barrier"; case .wall: return "wall"; case .relocate: return "relocate" }
    }
    var instructions: String {
        switch self {
        case .barrier: return "Choose an empty tile to place a barrier."
        case .wall: return "Choose two neighboring empty tiles."
        case .relocate: return "Choose your barrier, then its new tile."
        }
    }
}

struct ToolSupply: Codable, Equatable {
    var barriers: Int?
    var walls: Int
    var relocations: Int
    func count(for tool: TacticalTool) -> Int? {
        switch tool { case .barrier: return barriers; case .wall: return walls; case .relocate: return relocations }
    }
    mutating func spend(_ tool: TacticalTool) {
        switch tool {
        case .barrier: if let barriers { self.barriers = barriers - 1 }
        case .wall: walls -= 1
        case .relocate: relocations -= 1
        }
    }
}

enum MatchOutcome: String, Codable { case active, won, escaped, exhausted }
enum MatchPresentationPhase: Equatable { case choosing, executing, paused, won, lost }

struct TurnAction: Codable, Equatable {
    let tool: TacticalTool
    let positions: [PitchPosition]
}

struct MatchSnapshot: Codable, Equatable {
    var ball: PitchPosition
    var barriers: Set<PitchPosition> = []
    var supply: ToolSupply
    var moves = 0
    var outcome: MatchOutcome = .active
}

struct SavedMatch: Codable, Identifiable {
    var id = UUID()
    let levelID: String
    var snapshot: MatchSnapshot
    // Missing in older saves; nil keeps an in-progress match on its original map.
    var scenarioRevision: Int? = nil
    var starsEarned = 0
    var coinsEarned = 0
    var chapterBonusEarned: Int? = nil
}

struct StageLayout: Identifiable {
    let id: String
    let number: Int
    let chapter: Int
    let title: String
    let briefing: String
    let map: [String]
    let par: Int
    let supply: ToolSupply
    var moveLimit: Int? = nil
    var initialBarriers: Set<PitchPosition> = []
    var revision = 2
    var isChallenge: Bool { id.hasPrefix("challenge-") }
    var blocked: Set<PitchPosition> { positions(marked: "#") }
    var boosts: Set<PitchPosition> { positions(marked: ">") }
    var noBuild: Set<PitchPosition> { positions(marked: "~") }
    var start: PitchPosition { positions(marked: "B").first ?? PitchPosition(row: 5, column: 3) }
    var initial: MatchSnapshot { MatchSnapshot(ball: start, barriers: initialBarriers, supply: supply) }
    var isTraining: Bool { revision >= 2 && !isChallenge && number <= 2 }
    func positions(marked character: Character) -> Set<PitchPosition> {
        Set(map.enumerated().flatMap { row, text in text.enumerated().compactMap { col, value in
            value == character ? PitchPosition(row: row, column: col) : nil
        } })
    }
    func stars(for moves: Int) -> Int { moves <= par ? 3 : moves <= par + 2 ? 2 : 1 }
}

struct TrainingStep {
    let tool: TacticalTool
    let positions: [PitchPosition]
    let explanation: String
}

extension StageLayout {
    func trainingStep(after moves: Int) -> TrainingStep? {
        guard isTraining, moves < 2 else { return nil }
        if number == 1 {
            return TrainingStep(tool: .barrier,
                                positions: [PitchPosition(row: moves == 0 ? 8 : 2, column: 3)],
                                explanation: moves == 0
                                ? "Keep the ball inside. Tap the highlighted exit to build a barrier; the ball responds immediately."
                                : "The ball moved toward the other exit. Tap the highlighted tile to seal every route and win.")
        }
        return moves == 0
        ? TrainingStep(tool: .wall, positions: [PitchPosition(row: 2, column: 2), PitchPosition(row: 2, column: 3)],
                       explanation: "Choose Double wall. Close the wide upper gap with two neighboring barriers in just one turn.")
        : TrainingStep(tool: .relocate, positions: [PitchPosition(row: 7, column: 3), PitchPosition(row: 8, column: 3)],
                       explanation: "Choose Relocate. Reuse your red barrier to close the last exit: tap it, then the highlighted gap.")
    }
}

struct TurnResolution {
    let snapshot: MatchSnapshot
    let ballPath: [PitchPosition]
}
