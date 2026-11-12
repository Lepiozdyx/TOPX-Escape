import SwiftUI

struct RulesScreen: View {
    @ObservedObject var store: PlayerStore
    let feedback: FeedbackService
    let training: (() -> Void)?
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                ScreenHeading(eyebrow:"The playbook",title:"Think one move ahead.",subtitle:"Keep the ball on the pitch by closing every route to the outer edge. A completed placement immediately triggers the ball’s response.")
                RuleIllustration().frame(height:150).padding(16).background(PitchTheme.red,in:RoundedRectangle(cornerRadius:22))
                rule("01",icon:"barrier",title:"Tap. Build. Defend.",text:"Tap an empty tile to place a barrier and complete your turn immediately. If no escape route remains, you win immediately—even when the ball still has space inside your enclosure.")
                rule("02",icon:"wall",title:"Build a better defense.",text:"Barrier blocks one tile. Double wall blocks two neighboring tiles in one turn. Relocate moves one of your own barriers. Both tools are introduced in match 2, with one use each. From match 3, each attempt has two walls and two relocations. The second tile tap completes these actions automatically.")
                rule("03",icon:"boost",title:"Read the ground.",text:"Chevrons add one step in the direction the ball entered. A blocked second tile stops the extra step; acceleration never chains. Hatched ground is playable by the ball, but you cannot build there.")
                rule("04",icon:"shield",title:"A fair opponent.",text:"The ball follows the shortest escape route, counting acceleration as part of a turn. Equal routes always use the same direction priority. The ball responds once after each complete action. An unfinished two-tile selection does not spend a turn.")
                rule("05",icon:"pause",title:"Take a breather.",text:"Tap a selected tile again to cancel an unfinished selection, or switch tools. Completed turns are final. Restarting from the pause menu is free. Pausing or leaving saves your current attempt.")
                rule("06",icon:"star",title:"Earn your stars.",text:"Win for one star. Finish within target + 2 turns for two, or meet the target for three. Every newly earned star pays \(RewardRules.coinsPerStar) coins. Complete all four matches in a chapter for a one-time \(RewardRules.chapterCompletion)-coin bonus. Replays pay only for an improved star rating.")
                rule("07",icon:"trophy",title:"Take on extra time.",text:"Complete 16 campaign matches to unlock 12 challenges with limited turns and tools. Seal the last route before the limit. Use your coins to collect pitches and footballs; cosmetics never change the rules.")
                if let training {
                    Button {feedback.play(.tap);training()} label: {Text("Replay the two lessons")}.buttonStyle(SportButtonStyle())
                }
            }.padding(22)
        }.background(StadiumBackdrop()).navigationTitle("The playbook").navigationBarTitleDisplayMode(.inline)
    }
    private func rule(_ number:String,icon:String,title:String,text:String) -> some View {
        Panel {
            VStack(alignment:.leading,spacing:13) {
                HStack {SportIcon(icon,size:24).foregroundStyle(PitchTheme.red);Spacer();SectionEyebrow(text:number)}
                Text(title).font(.system(size:23,weight:.semibold,design:.serif)).foregroundStyle(PitchTheme.ink)
                Text(text).font(.system(size:13)).lineSpacing(5).foregroundStyle(PitchTheme.muted)
            }
        }
    }
}

struct RuleIllustration: View {
    var body: some View {
        HStack(spacing:22) {
            VStack(alignment:.leading,spacing:10) {
                SectionEyebrow(text:"The winning shape",color:.white.opacity(0.6))
                Text("Seal the route.\nKeep the ball.").font(.system(size:23,weight:.medium,design:.serif)).foregroundStyle(.white)
                HStack(spacing:5) {SportIcon("check",size:13);Text("All exits closed").font(.system(size:10,weight:.medium))}.foregroundStyle(Color(hex:0xE9D5B5))
            }
            Spacer(minLength:0)
            ZStack {
                ForEach(0..<6) {index in
                    HexTile().fill(PitchTheme.red).frame(width:34,height:39)
                        .overlay(SportIcon("barrier",size:19).foregroundStyle(Color(hex:0xF5E6D2)))
                        .offset(x:cos(Double(index) * .pi/3)*41,y:sin(Double(index) * .pi/3)*41)
                }
                FootballView().frame(width:35,height:35)
            }.frame(width:114,height:124)
        }
    }
}
