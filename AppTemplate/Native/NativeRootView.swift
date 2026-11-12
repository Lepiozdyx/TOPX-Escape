import SwiftUI
import AVFoundation

struct NativeRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = PlayerStore()
    private let feedback = FeedbackService()
    var body: some View {
        HomeScreen(store:store,feedback:feedback)
            .tint(PitchTheme.red)
            .onAppear {feedback.configure(store.save.settings)}
            .onChange(of:store.save.settings) {_, settings in feedback.configure(settings)}
            .onChange(of:scenePhase) {_, phase in feedback.setActive(phase == .active)}
            .onReceive(NotificationCenter.default.publisher(for:AVAudioSession.interruptionNotification)) { notification in
                guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue:raw) else {return}
                feedback.setActive(type == .ended && scenePhase == .active)
            }
    }
}
