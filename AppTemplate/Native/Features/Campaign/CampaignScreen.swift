import SwiftUI

struct CampaignScreen: View {
    @ObservedObject var store: PlayerStore
    let feedback: FeedbackService
    let openLevel: (StageLayout) -> Void
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:26) {
                ForEach(StageCatalog.chapters) { chapter in
                    VStack(alignment:.leading,spacing:14) {
                        HStack(alignment:.top,spacing:14) {
                            Text(chapter.number).font(.system(size:36,weight:.light,design:.serif)).foregroundStyle(PitchTheme.red.opacity(0.5))
                            VStack(alignment:.leading,spacing:5) {
                                Text(chapter.title).font(.system(size:22,weight:.semibold,design:.serif)).foregroundStyle(PitchTheme.ink)
                                Text(chapter.subtitle).font(.system(size:12)).foregroundStyle(PitchTheme.muted)
                            }
                        }
                        VStack(spacing:0) {
                            ForEach(StageCatalog.campaign.filter {$0.chapter == chapter.id}) { level in
                                LevelRow(level:level,record:store.save.records[level.id],unlocked:store.isUnlocked(level)) {feedback.play(.tap);openLevel(level)}
                                if level.number % 4 != 0 {Divider().padding(.leading,60)}
                            }
                        }.background(.white,in:RoundedRectangle(cornerRadius:20))
                    }
                }
            }.padding(22)
        }.background(StadiumBackdrop()).navigationTitle("Campaign").navigationBarTitleDisplayMode(.inline)
    }
}

struct LevelRow: View {
    let level: StageLayout
    let record: LevelRecord?
    let unlocked: Bool
    let action: () -> Void
    var body: some View {
        Button(action:action) {
            HStack(spacing:14) {
                ZStack {
                    RoundedRectangle(cornerRadius:11).fill(unlocked ? PitchTheme.red.opacity(0.08) : PitchTheme.paper).frame(width:40,height:44)
                    if unlocked {Text(String(format:"%02d",level.number)).font(.system(size:17,weight:.medium,design:.rounded)).foregroundStyle(PitchTheme.red)}
                    else {SportIcon("lock",size:17).foregroundStyle(PitchTheme.muted.opacity(0.55))}
                }
                VStack(alignment:.leading,spacing:5) {
                    Text(level.title).font(.system(size:14,weight:.semibold)).foregroundStyle(PitchTheme.ink)
                    if level.isChallenge {
                        Text("\(level.moveLimit ?? 0) turns · Target \(level.par)")
                            .font(.system(size:11)).foregroundStyle(PitchTheme.muted)
                    }
                }
                Spacer(minLength:2)
                if let record {StarRating(value:record.stars,size:11)}
                else if unlocked {SportIcon("arrow",size:17).foregroundStyle(PitchTheme.red)}
            }.padding(14).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!unlocked).opacity(unlocked ? 1 : 0.55)
    }
}

struct ChallengeScreen: View {
    @ObservedObject var store: PlayerStore
    let feedback: FeedbackService
    let openLevel: (StageLayout) -> Void
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                ScreenHeading(eyebrow:"Extra time",title:"Rise to the challenge.",subtitle:"Twelve tactical fixtures. Limited tools, limited turns, unlimited room to improve.")
                if !store.challengesUnlocked {
                    Panel {
                        VStack(alignment:.leading,spacing:16) {
                            SportIcon("lock",size:32).foregroundStyle(PitchTheme.red)
                            Text("Earn your place.").font(.system(size:25,weight:.semibold,design:.serif))
                            Text("Complete all 16 campaign matches to unlock the challenge series.").font(.system(size:14)).foregroundStyle(PitchTheme.muted)
                            ProgressView(value:Double(store.campaignWins),total:16).tint(PitchTheme.red)
                            Text("\(store.campaignWins) of 16 complete").font(.system(size:12,weight:.medium)).foregroundStyle(PitchTheme.red)
                        }
                    }
                }
                VStack(spacing:0) {
                    ForEach(StageCatalog.challenges) { level in
                        LevelRow(level:level,record:store.save.records[level.id],unlocked:store.challengesUnlocked) {feedback.play(.tap);openLevel(level)}
                        if level.number != 12 {Divider().padding(.leading,60)}
                    }
                }.background(.white,in:RoundedRectangle(cornerRadius:20))
            }.padding(22)
        }.background(StadiumBackdrop()).navigationTitle("Challenges").navigationBarTitleDisplayMode(.inline)
    }
}
