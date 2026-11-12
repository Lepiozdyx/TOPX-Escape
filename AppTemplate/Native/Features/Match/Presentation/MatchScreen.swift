import SwiftUI

struct MatchScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var controller: MatchController
    @ObservedObject private var store: PlayerStore
    @State private var showBriefing: Bool
    @State private var showRules = false
    let feedback: FeedbackService
    let openLevel: (StageLayout) -> Void

    init(match: SavedMatch, store: PlayerStore, feedback: FeedbackService, resume: Bool, openLevel: @escaping (StageLayout) -> Void) {
        self._controller = StateObject(wrappedValue:MatchController(match:match,store:store,feedback:feedback,resume:resume))
        self.store = store; self.feedback = feedback; self.openLevel = openLevel
        self._showBriefing = State(initialValue: !resume && match.levelID.hasPrefix("challenge-"))
    }
    private var level: StageLayout { controller.level }
    private var terminal: Bool { controller.phase == .won || controller.phase == .lost }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 680
            VStack(spacing:compact ? 8 : 12) {
                header(compact:compact)
                PitchBoard(level:level,snapshot:controller.match.snapshot,selected:controller.selected,highlighted:controller.highlightedTiles,tool:controller.tool,suggestedTool:controller.trainingStep?.tool,
                           visibleBall:controller.visibleBall,
                           trail:controller.lastTrail,fieldStyle:store.save.selectedField,ballStyle:store.save.selectedBall,
                           rotation:controller.rollAngle,interactive:controller.phase == .choosing && !showBriefing,onTap:{ controller.select($0, reduceMotion:reduceMotion) })
                    .frame(maxWidth:.infinity,maxHeight:.infinity)
                    .layoutPriority(1)
                toolBar
                if let instruction = controller.instruction {
                    Text(instruction).font(.system(size:compact ? 12 : 13,weight:.medium))
                        .foregroundStyle(.white).lineSpacing(2)
                        .frame(maxWidth:.infinity,alignment:.leading)
                        .padding(.horizontal,12).padding(.vertical,compact ? 8 : 10)
                        .background(PitchTheme.matchPanel.opacity(0.94),in:RoundedRectangle(cornerRadius:12))
                        .fixedSize(horizontal:false,vertical:true)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }.padding(.horizontal,8).padding(.top,8).padding(.bottom,8)
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .accessibilityHidden(showBriefing || controller.phase == .paused || terminal)
        }
        .background(PitchSurface(style:store.save.selectedField,showsMarkings:false).ignoresSafeArea()).toolbar(.hidden,for:.navigationBar)
        .overlay {
            if showBriefing && controller.phase != .paused { briefingOverlay }
            else if controller.phase == .paused { pauseOverlay }
            else if terminal { resultOverlay }
        }
        .animation(reduceMotion ? nil : .easeOut(duration:0.18), value:controller.phase)
        .preferredColorScheme(.dark)
        .environment(\.colorScheme,.dark)
        .sheet(isPresented:$showRules) { NavigationStack { RulesScreen(store:store,feedback:feedback,training:nil) }.environment(\.colorScheme,.light).preferredColorScheme(.light) }
        .onChange(of:scenePhase) { _, phase in if phase != .active { controller.pause() } }
        .onDisappear { controller.leave() }
    }

    private func header(compact:Bool) -> some View {
        HStack(spacing:10) {
            IconButton(icon:"pause",label:"Pause match",light:true) { controller.pause() }
            VStack(alignment:.leading,spacing:3) {
                SectionEyebrow(text:level.isChallenge ? "Challenge \(level.number)" : "Chapter \(level.chapter) · Match \(level.number)",color:PitchTheme.matchMuted)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(level.title).font(.system(size:compact ? 20 : 23,weight:.semibold,design:.serif))
                    .foregroundStyle(Color.white).lineLimit(1).minimumScaleFactor(0.75)
            }.frame(maxWidth:.infinity,alignment:.leading)
            VStack(alignment:.trailing,spacing:3) {
                Text("\(controller.match.snapshot.moves)\(level.moveLimit.map { "/\($0)" } ?? "")")
                    .font(.system(size:22,weight:.medium,design:.rounded)).monospacedDigit().foregroundStyle(.white)
                Text("TURNS · PAR \(level.par)").font(.system(size:8,weight:.bold,design:.monospaced))
                    .tracking(1).foregroundStyle(PitchTheme.matchMuted)
            }.fixedSize()
        }
    }
    private var toolBar: some View {
        HStack(spacing:8) {
            ForEach(TacticalTool.allCases) { tool in
                let count = controller.match.snapshot.supply.count(for:tool)
                let available = controller.isToolAvailable(tool)
                let suggested = controller.trainingStep?.tool == tool
                let chosen = controller.tool == tool
                Button { controller.chooseTool(tool) } label: {
                    VStack(spacing:5) {
                        HStack(spacing:7) {
                            SportIcon(tool.symbol,size:18)
                            Text(count.map(String.init) ?? "∞").font(.system(size:12,weight:.semibold,design:.rounded))
                        }
                        Text(tool.title).font(.system(size:10,weight:.semibold)).lineLimit(1).minimumScaleFactor(0.8)
                    }.frame(maxWidth:.infinity).frame(height:50)
                        .foregroundStyle(.white)
                        .background(chosen ? PitchTheme.red : Color.white.opacity(0.1),in:RoundedRectangle(cornerRadius:13))
                        .overlay(RoundedRectangle(cornerRadius:13).strokeBorder(suggested ? .white : chosen ? .clear : .white.opacity(0.2),lineWidth:suggested ? 2 : 1))
                }.buttonStyle(.plain).disabled(!available)
                    .opacity(available ? 1 : 0.35).accessibilityLabel("\(tool.title), \(count.map(String.init) ?? "unlimited") uses")
                    .accessibilityAddTraits(chosen ? .isSelected : [])
            }
        }
    }
    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            ScrollView {
                VStack(spacing:20,content:content).padding(26).frame(maxWidth:350)
                    .foregroundStyle(.white)
                    .background(PitchTheme.matchPanel,in:RoundedRectangle(cornerRadius:28))
                    .overlay(RoundedRectangle(cornerRadius:28).strokeBorder(.white.opacity(0.18)))
                    .padding(20).frame(maxWidth:.infinity)
            }.scrollBounceBehavior(.basedOnSize).frame(maxHeight:620)
        }.accessibilityAddTraits(.isModal)
    }
    private var briefingOverlay: some View {
        modal {
            SportIcon(level.isChallenge ? "trophy" : "shield",size:38).foregroundStyle(.white)
            SectionEyebrow(text:"Tactical challenge",color:PitchTheme.matchMuted)
            Text(level.title).font(.system(size:29,weight:.semibold,design:.serif)).multilineTextAlignment(.center)
            Text(level.briefing).font(.system(size:15)).lineSpacing(4).foregroundStyle(PitchTheme.matchMuted).multilineTextAlignment(.center)
            if let limit = level.moveLimit {
                Text("\(limit) turns · \(level.supply.barriers ?? 0) barriers · \(level.supply.walls) double walls · \(level.supply.relocations) relocations")
                    .font(.system(size:12,weight:.medium)).foregroundStyle(.white).multilineTextAlignment(.center)
            }
            Button { showBriefing = false; feedback.play(.tap) } label: { Text("Take the pitch") }.buttonStyle(SportButtonStyle())
        }
    }
    private var pauseOverlay: some View {
        modal {
            SectionEyebrow(text:"Take a breather",color:PitchTheme.matchMuted)
            Text("Half-time.").font(.system(size:36,weight:.semibold,design:.serif))
            Text("Your match is saved. Pick up exactly where you left off.").font(.system(size:14)).foregroundStyle(PitchTheme.matchMuted).multilineTextAlignment(.center)
            Button { showBriefing = false; controller.resume() } label: { Text("Resume match") }.buttonStyle(SportButtonStyle())
            Button { controller.retry(); showBriefing = level.isChallenge } label: { Text("Restart match") }.buttonStyle(SportButtonStyle(prominent:false,light:true))
            Button { showRules = true } label: { Text("How to play").font(.system(size:14,weight:.medium)).foregroundStyle(.white) }
            Button { dismiss() } label: { Text("Save & leave").font(.system(size:14)).foregroundStyle(PitchTheme.matchMuted) }
        }
    }
    private var resultOverlay: some View {
        let won = controller.phase == .won
        return modal {
            SportIcon(won ? "trophy" : "shield",size:42).foregroundStyle(.white)
            SectionEyebrow(text:won ? "Full-time · All exits sealed" : "Full-time · Try a new defense",color:PitchTheme.matchMuted)
            Text(won ? "Beautiful defense." : "Another chance.").font(.system(size:31,weight:.semibold,design:.serif)).multilineTextAlignment(.center)
            if won {
                StarRating(value:controller.match.starsEarned,size:31)
                Text("\(controller.match.snapshot.moves) \(controller.match.snapshot.moves == 1 ? "turn" : "turns") · Target \(level.par)").font(.system(size:14)).foregroundStyle(PitchTheme.matchMuted)
                HStack { SportIcon("coin",size:18); Text("+\(controller.match.coinsEarned) coins") }.font(.system(size:16,weight:.semibold)).foregroundStyle(.white)
                if let bonus = controller.match.chapterBonusEarned, bonus > 0 {
                    VStack(spacing:5) {
                        Text("Chapter \(level.chapter) complete").font(.system(size:14,weight:.semibold))
                        Text("\(controller.match.coinsEarned - bonus) from stars · \(bonus) chapter bonus")
                            .font(.system(size:12)).foregroundStyle(PitchTheme.matchMuted)
                    }
                }
                if !level.isChallenge && level.number == 16 {
                    Text("Campaign complete. Twelve new tactical challenges are waiting for you.").font(.system(size:14)).foregroundStyle(PitchTheme.matchMuted).multilineTextAlignment(.center)
                }
            } else {
                Text(controller.match.snapshot.outcome == .escaped ? "The ball reached the touchline. Close the route earlier." : "You ran out of turns or tools. Try closing several routes with a single wall.")
                    .font(.system(size:14)).foregroundStyle(PitchTheme.matchMuted).multilineTextAlignment(.center)
            }
            if won, let next = nextStage {
                Button { openLevel(next) } label: { Text(level.isTraining ? level.number == 1 ? "Next lesson" : "Play on your own" : "Next match") }.buttonStyle(SportButtonStyle())
            } else if won && !level.isChallenge {
                Button { dismiss() } label: { Text("Return to the club") }.buttonStyle(SportButtonStyle())
            }
            Button { controller.retry(); showBriefing = false } label: { Text(won ? "Play again" : "Try again") }.buttonStyle(SportButtonStyle(prominent:!won,light:true))
            Button { dismiss() } label: { Text("Back to club").font(.system(size:14)).foregroundStyle(PitchTheme.matchMuted) }
        }
    }
    private var nextStage: StageLayout? {
        let catalog = level.isChallenge ? StageCatalog.challenges : StageCatalog.campaign
        guard let index = catalog.firstIndex(where:{$0.id == level.id}), index+1 < catalog.count else { return nil }
        return catalog[index+1]
    }
}
