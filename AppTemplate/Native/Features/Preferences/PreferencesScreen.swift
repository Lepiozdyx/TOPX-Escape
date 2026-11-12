import SwiftUI

struct PreferencesScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: PlayerStore
    let feedback: FeedbackService
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:24) {
                    VStack(spacing:0) {
                        preference(icon:"music",title:"Background music",value:\.music)
                        Divider().padding(.leading,58)
                        preference(icon:"sound",title:"Sound effects",value:\.effects)
                        Divider().padding(.leading,58)
                        preference(icon:"haptic",title:"Haptic feedback",value:\.haptics)
                    }.padding(.horizontal,18).background(.white,in:RoundedRectangle(cornerRadius:20))
                }.padding(22)
            }.background(StadiumBackdrop()).navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
                .toolbar {ToolbarItem(placement:.topBarTrailing) {Button("Done") {dismiss()}.fontWeight(.semibold)}}
        }
    }
    private func preference(icon:String,title:String,value:WritableKeyPath<PlayerSettings,Bool>) -> some View {
        HStack(spacing:14) {
            SportIcon(icon,size:23).foregroundStyle(PitchTheme.red)
            Toggle(isOn:Binding(get:{store.save.settings[keyPath:value]},set:{newValue in
                store.updateSettings {$0[keyPath:value] = newValue}
                feedback.configure(store.save.settings)
                if newValue {feedback.play(.tap)}
            })) {
                Text(title).font(.system(size:14,weight:.semibold)).foregroundStyle(PitchTheme.ink)
            }.tint(PitchTheme.red)
        }.padding(.vertical,19)
    }
}
