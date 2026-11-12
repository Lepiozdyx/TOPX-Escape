import SwiftUI

@MainActor
final class MatchController: ObservableObject {
    @Published private(set) var match: SavedMatch
    @Published private(set) var phase: MatchPresentationPhase
    @Published private(set) var selected: [PitchPosition] = []
    @Published private(set) var tool: TacticalTool = .barrier
    @Published private(set) var visibleBall: PitchPosition
    @Published private(set) var rollAngle: Double = 0
    @Published private(set) var lastTrail: [PitchPosition] = []
    @Published private(set) var message: String?
    @Published private(set) var level: StageLayout
    let store: PlayerStore
    let feedback: FeedbackService
    private var animationTask: Task<Void, Never>?
    private var executingInstruction: String?

    init(match: SavedMatch, store: PlayerStore, feedback: FeedbackService, resume: Bool) {
        self.match = match
        self.level = StageCatalog.level(match.levelID, revision: match.scenarioRevision) ?? StageCatalog.campaign[0]
        self.store = store
        self.feedback = feedback
        self.visibleBall = match.snapshot.ball
        self.phase = resume && match.snapshot.outcome == .active ? .paused : Self.presentation(match.snapshot.outcome)
    }
    deinit { animationTask?.cancel() }
    static func presentation(_ outcome: MatchOutcome) -> MatchPresentationPhase {
        switch outcome { case .active: return .choosing; case .won: return .won; case .escaped, .exhausted: return .lost }
    }
    var action: TurnAction { TurnAction(tool: tool, positions: selected) }
    var trainingStep: TrainingStep? { level.trainingStep(after: match.snapshot.moves) }
    var highlightedTiles: Set<PitchPosition> {
        guard let step = trainingStep else { return [] }
        if step.tool == .relocate { return Set([step.positions[selected.isEmpty ? 0 : 1]]) }
        return Set(step.positions).subtracting(selected)
    }
    var instruction: String? {
        // Keep the board geometry steady while the ball is moving.
        if phase == .executing { return executingInstruction }
        guard phase == .choosing else { return nil }
        if let message { return message }
        if tool == .wall && selected.count == 1 { return "Tap a neighboring empty tile to build both barriers and complete the turn." }
        if tool == .relocate && selected.count == 1 { return "Tap an empty destination to move this barrier and complete the turn." }
        return trainingStep?.explanation
    }
    func isToolAvailable(_ value: TacticalTool) -> Bool {
        phase == .choosing && (match.snapshot.supply.count(for: value) ?? 1) > 0 &&
        (trainingStep == nil || trainingStep?.tool == value)
    }

    func chooseTool(_ value: TacticalTool) {
        guard phase == .choosing else { return }
        guard trainingStep == nil || trainingStep?.tool == value else { return }
        guard (match.snapshot.supply.count(for: value) ?? 1) > 0 else { message = "No uses left for this tool."; return }
        tool = value; selected = []; message = nil; feedback.play(.tap)
    }
    func select(_ position: PitchPosition, reduceMotion: Bool) {
        guard phase == .choosing else { return }
        let previousInstruction = instruction
        message = nil
        if selected.contains(position) { selected = []; return }
        if let step = trainingStep {
            guard tool == step.tool else { message = "Choose \(step.tool.title) to try this tactic."; return }
            guard highlightedTiles.contains(position) else { message = "Follow the highlighted tile to try this tactic."; return }
        }
        if tool == .relocate && selected.isEmpty {
            guard match.snapshot.barriers.contains(position) else { message = "Select a barrier you placed first."; return }
            selected = [position]
        } else {
            guard MatchEngine.canBuild(position, in: match.snapshot, level: level) else {
                message = level.noBuild.contains(position) ? "Protected ground: no building here." : "Choose a free tile."; return
            }
            switch tool {
            case .barrier: selected = [position]
            case .wall:
                if selected.isEmpty { selected = [position] }
                else if selected[0].neighbors.contains(position) { selected.append(position) }
                else { message = "Choose a tile next to the selected barrier."; return }
            case .relocate: selected.append(position)
            }
        }
        if MatchEngine.isValid(action, in: match.snapshot, level: level) {
            execute(reduceMotion: reduceMotion, keepingInstruction: previousInstruction)
        }
        else { feedback.play(.tap) }
    }

    private func execute(reduceMotion: Bool, keepingInstruction: String?) {
        guard phase == .choosing, let resolution = MatchEngine.resolve(action, in: match.snapshot, level: level) else { return }
        executingInstruction = keepingInstruction
        match.snapshot = resolution.snapshot
        phase = .executing
        selected = []; message = nil
        // Persist the complete turn and award atomically before the visual sequence.
        match = store.record(match, level: level)
        feedback.play(tool == .relocate ? .relocate : .build)
        let path = resolution.ballPath
        let origin = visibleBall
        animationTask?.cancel()
        animationTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: .milliseconds(reduceMotion ? 40 : 160))
                for position in path {
                    try Task.checkCancellation()
                    self.lastTrail = [origin] + path
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                        self.visibleBall = position
                        self.rollAngle += 100
                    }
                    self.feedback.play(.roll)
                    try await Task.sleep(for: .milliseconds(reduceMotion ? 30 : 270))
                }
                try Task.checkCancellation()
                self.finishPresentation()
            } catch { }
        }
    }
    private func finishPresentation() {
        visibleBall = match.snapshot.ball
        phase = Self.presentation(match.snapshot.outcome)
        lastTrail = []
        if phase == .won { feedback.play(.victory) }
        if phase == .lost { feedback.play(.defeat) }
        if (match.snapshot.supply.count(for: tool) ?? 1) == 0 { tool = .barrier }
    }
    func pause() {
        animationTask?.cancel(); animationTask = nil
        visibleBall = match.snapshot.ball; lastTrail = []; selected = []; message = nil
        phase = match.snapshot.outcome == .active ? .paused : Self.presentation(match.snapshot.outcome)
    }
    func resume() {
        guard phase == .paused else { return }
        if (match.snapshot.supply.count(for: tool) ?? 1) == 0 { tool = .barrier }
        phase = .choosing; feedback.play(.tap)
    }
    func retry() {
        animationTask?.cancel(); animationTask = nil
        match = store.begin(level); selected = []; message = nil; tool = .barrier
        level = StageCatalog.level(match.levelID, revision: match.scenarioRevision) ?? level
        visibleBall = match.snapshot.ball; rollAngle = 0; lastTrail = []; phase = .choosing
        feedback.play(.tap)
    }
    func leave() { pause() }
}
