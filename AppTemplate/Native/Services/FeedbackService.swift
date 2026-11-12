import AVFoundation
import UIKit

@MainActor
final class FeedbackService {
    enum Cue: String, CaseIterable { case tap, build, relocate, roll, purchase, victory, defeat }
    private let music: AVAudioPlayer?
    private var effects: [Cue: AVAudioPlayer] = [:]
    private var settings = PlayerSettings()
    private var active = true

    init() {
        if let url = Bundle.main.url(forResource: "backgroundmusic", withExtension: "mp3") { music = try? AVAudioPlayer(contentsOf: url) }
        else { music = nil }
        music?.numberOfLoops = -1
        music?.volume = 0.38
        music?.prepareToPlay()
        for cue in Cue.allCases {
            if let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav", subdirectory: "Sounds") ?? Bundle.main.url(forResource: cue.rawValue, withExtension: "wav"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay(); effects[cue] = player
            }
        }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func configure(_ settings: PlayerSettings) {
        self.settings = settings
        updateMusic()
    }
    func setActive(_ active: Bool) {
        self.active = active
        if !active { effects.values.forEach { $0.stop() } }
        else { try? AVAudioSession.sharedInstance().setActive(true) }
        updateMusic()
    }
    private func updateMusic() {
        if active && settings.music && !AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint { music?.play() }
        else { music?.pause() }
    }
    func play(_ cue: Cue) {
        guard active else { return }
        if settings.effects, let player = effects[cue] { player.currentTime = 0; player.play() }
        guard settings.haptics else { return }
        switch cue {
        case .victory, .purchase: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .defeat: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .build, .relocate: UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.65)
        case .tap: UISelectionFeedbackGenerator().selectionChanged()
        case .roll: break
        }
    }
}
