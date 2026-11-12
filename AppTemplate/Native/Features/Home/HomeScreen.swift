import SwiftUI

struct MatchRoute: Identifiable {
    let id = UUID()
    let match: SavedMatch
    let resume: Bool
}

struct HomeScreen: View {
    @ObservedObject var store: PlayerStore
    let feedback: FeedbackService
    @State private var route: MatchRoute?
    @State private var showSettings = false
    @State private var pendingLevel: StageLayout?
    @State private var homeVisible = true

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let naturalHeight = geometry.size.width * 402 / 390
                // Give the match controls and navigation first claim on vertical space.
                let availableHeight = geometry.size.height - 343
                let posterHeight = max(246, min(naturalHeight, availableHeight))
                ScrollView {
                    VStack(spacing: 0) {
                        ArcadePoster {
                            feedback.play(.tap)
                            showSettings = true
                        }
                        .frame(height: posterHeight)

                        VStack(alignment: .leading, spacing: 0) {
                            matchMenu
                            campaignLink.padding(.top, 22)
                            clubLinks.padding(.top, 24)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 15)
                        .padding(.bottom, 12)
                        .background(PitchTheme.paper)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .background(alignment: .top) {
                VStack(spacing: 0) {
                    PitchTheme.red.frame(height: 100)
                    PitchTheme.paper
                }
                .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { homeVisible = true }
            .onDisappear { homeVisible = false }
        }
        .environment(\.colorScheme,.light)
        .preferredColorScheme(homeVisible ? .dark : .light)
        .sheet(isPresented:$showSettings) { PreferencesScreen(store:store,feedback:feedback).preferredColorScheme(.light) }
        .fullScreenCover(item:$route) { route in
            MatchScreen(match:route.match,store:store,feedback:feedback,resume:route.resume) { level in
                self.route = MatchRoute(match:store.begin(level),resume:false)
            }.id(route.id)
        }
        .alert(pendingLevel == nil ? "Local save" : "Start a new match?",isPresented:Binding(
            get:{pendingLevel != nil || store.storageMessage != nil},
            set:{if !$0 {pendingLevel = nil;store.dismissStorageMessage()}}
        )) {
            if let level = pendingLevel {
                Button("Keep current match",role:.cancel) {pendingLevel = nil}
                Button("Start new match") {
                    route = MatchRoute(match:store.begin(level),resume:false)
                    pendingLevel = nil
                }
            } else {
                Button("OK") {store.dismissStorageMessage()}
            }
        } message: {
            Text(pendingLevel == nil ? store.storageMessage ?? "" : "Your current attempt will be replaced. Your stars, coins and collection stay with you.")
        }
    }
    private var matchMenu: some View {
        let resume = store.hasUnfinishedMatch
        let level = resume
            ? store.save.match.flatMap { StageCatalog.level($0.levelID, revision: $0.scenarioRevision) }
            : store.nextLevel
        let status = resume ? "MATCH IN PROGRESS" : store.challengesUnlocked ? "CAMPAIGN COMPLETE" : "NEXT MATCH"
        let number = level.map { $0.number.formatted(.number.precision(.integerLength(2))) }

        return VStack(alignment: .leading, spacing: 3) {
            Text(number.map { "\(status)  /  \($0)" } ?? status)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(PitchTheme.red)
            Text(level?.title ?? "Continue match")
                .font(.custom("AvenirNextCondensed-Heavy", fixedSize: 39))
                .foregroundStyle(PitchTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Button {
                feedback.play(.tap)
                if store.hasUnfinishedMatch, let match = store.save.match {
                    route = MatchRoute(match: match, resume: true)
                } else {
                    route = MatchRoute(match: store.begin(store.nextLevel), resume: false)
                }
            } label: {
                HStack(spacing: 10) {
                    Text(resume ? "RESUME MATCH" : "TAKE THE PITCH")
                        .font(.custom("AvenirNextCondensed-HeavyItalic", fixedSize: 29))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 0)
                    SportIcon("arrow", size: 26)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 23)
                .frame(height: 62)
                .background {
                    ZStack {
                        SlantedMatchButton().fill(PitchTheme.ink).offset(y: 8)
                        SlantedMatchButton().fill(PitchTheme.red)
                    }
                }
                .contentShape(SlantedMatchButton())
                .padding(.bottom, 8)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private var campaignLink: some View {
        let wins = store.campaignWins
        let total = StageCatalog.campaign.count

        return NavigationLink {
            CampaignScreen(store: store, feedback: feedback, openLevel: requestOpen)
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("CAMPAIGN")
                        .font(.custom("AvenirNextCondensed-HeavyItalic", fixedSize: 29))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 0)
                    Text("\(wins) / \(total) WON")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(PitchTheme.muted)
                    SportIcon("arrow", size: 19)
                }
                .foregroundStyle(PitchTheme.ink)
                HStack(spacing: 4) {
                    ForEach(0..<total, id: \.self) { index in
                        Rectangle()
                            .fill(index < wins ? PitchTheme.red : PitchTheme.line)
                            .frame(height: 5)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var clubLinks: some View {
        let unlocked = store.challengesUnlocked

        return VStack(spacing: 12) {
            Rectangle().fill(PitchTheme.ink).frame(height: 1.5)
            HStack(alignment: .top, spacing: 0) {
                NavigationLink {
                    ChallengeScreen(store: store, feedback: feedback, openLevel: requestOpen)
                } label: {
                    clubLabel("Challenges", icon: unlocked ? "trophy" : "lock",
                              subtitle: unlocked ? nil : "\(StageCatalog.campaign.count) WINS")
                }
                clubDivider
                NavigationLink {
                    CollectionScreen(store: store, feedback: feedback)
                } label: {
                    clubLabel("Collection", icon: "collection")
                }
                clubDivider
                NavigationLink {
                    RulesScreen(store: store, feedback: feedback, training: { requestOpen(StageCatalog.campaign[0]) })
                } label: {
                    clubLabel("Playbook", icon: "rules")
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var clubDivider: some View {
        Rectangle().fill(PitchTheme.line).frame(width: 1, height: 55)
    }

    private func clubLabel(_ title: String, icon: String, subtitle: String? = nil) -> some View {
        VStack(spacing: 4) {
            SportIcon(icon, size: 22)
                .foregroundStyle(subtitle == nil ? PitchTheme.red : PitchTheme.muted)
            Text(title)
                .font(.custom("AvenirNext-DemiBold", fixedSize: 14))
                .foregroundStyle(PitchTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(PitchTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .top)
        .contentShape(Rectangle())
    }

    private func requestOpen(_ level:StageLayout) {
        guard store.isUnlocked(level) else {return}
        if store.hasUnfinishedMatch { pendingLevel = level }
        else {route = MatchRoute(match:store.begin(level),resume:false)}
    }
}

private struct SlantedMatchButton: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addLines([
                CGPoint(x: rect.minX + 10, y: rect.minY),
                CGPoint(x: rect.maxX, y: rect.minY),
                CGPoint(x: rect.maxX - 10, y: rect.maxY),
                CGPoint(x: rect.minX, y: rect.maxY)
            ])
            path.closeSubpath()
        }
    }
}
