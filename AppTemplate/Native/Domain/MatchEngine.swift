import Foundation

enum MatchEngine {
    static func canBuild(_ position: PitchPosition, in state: MatchSnapshot, level: StageLayout) -> Bool {
        position.isInside && position != state.ball && !level.blocked.contains(position) &&
        !level.noBuild.contains(position) && !state.barriers.contains(position)
    }

    static func isValid(_ action: TurnAction, in state: MatchSnapshot, level: StageLayout) -> Bool {
        guard state.outcome == .active, (state.supply.count(for: action.tool) ?? 1) > 0 else { return false }
        let cells = action.positions
        switch action.tool {
        case .barrier:
            return cells.count == 1 && canBuild(cells[0], in: state, level: level)
        case .wall:
            return cells.count == 2 && cells[0].neighbors.contains(cells[1]) && cells.allSatisfy { canBuild($0, in: state, level: level) }
        case .relocate:
            return cells.count == 2 && state.barriers.contains(cells[0]) && canBuild(cells[1], in: state, level: level)
        }
    }

    static func resolve(_ action: TurnAction, in state: MatchSnapshot, level: StageLayout) -> TurnResolution? {
        guard isValid(action, in: state, level: level) else { return nil }
        var next = state
        if action.tool == .relocate { next.barriers.remove(action.positions[0]); next.barriers.insert(action.positions[1]) }
        else { next.barriers.formUnion(action.positions) }
        next.supply.spend(action.tool)
        next.moves += 1
        guard let path = escapeStep(in: next, level: level) else {
            next.outcome = .won
            return TurnResolution(snapshot: next, ballPath: [])
        }
        next.ball = path.last ?? next.ball
        if path.contains(where: \.isBoundary) { next.outcome = .escaped }
        else if let limit = level.moveLimit, next.moves >= limit { next.outcome = .exhausted }
        else if !hasLegalAction(in:next, level:level) { next.outcome = .exhausted }
        return TurnResolution(snapshot: next, ballPath: path)
    }

    private static func hasLegalAction(in state: MatchSnapshot, level: StageLayout) -> Bool {
        let free = Set(PitchRules.positions.filter { canBuild($0, in:state, level:level) })
        guard !free.isEmpty else {return false}
        if (state.supply.barriers ?? 1) > 0 {return true}
        if state.supply.relocations > 0 && !state.barriers.isEmpty {return true}
        return state.supply.walls > 0 && free.contains { cell in cell.neighbors.contains(where:free.contains) }
    }

    private struct SearchNode {
        let position: PitchPosition
        let firstStep: [PitchPosition]
    }

    static func escapeStep(in state: MatchSnapshot, level: StageLayout) -> [PitchPosition]? {
        let occupied = level.blocked.union(state.barriers)
        var queue = [SearchNode(position: state.ball, firstStep: [])]
        var visited: Set<PitchPosition> = [state.ball]
        var index = 0
        while index < queue.count {
            let current = queue[index]
            index += 1
            for direction in 0..<6 {
                let path = travel(from: current.position, direction: direction, occupied: occupied, boosts: level.boosts)
                guard let destination = path.last else { continue }
                let first = current.firstStep.isEmpty ? path : current.firstStep
                if path.contains(where: \.isBoundary) { return first }
                if visited.insert(destination).inserted { queue.append(SearchNode(position: destination, firstStep: first)) }
            }
        }
        return nil
    }

    static func travel(from start: PitchPosition, direction: Int, occupied: Set<PitchPosition>, boosts: Set<PitchPosition>) -> [PitchPosition] {
        let first = start.neighbor(direction)
        guard first.isInside, !occupied.contains(first) else { return [] }
        if first.isBoundary || !boosts.contains(first) { return [first] }
        let second = first.neighbor(direction)
        guard second.isInside, !occupied.contains(second) else { return [first] }
        return [first, second]
    }
}
