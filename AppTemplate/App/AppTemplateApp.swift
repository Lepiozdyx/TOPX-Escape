import SwiftUI

@main
struct AppTemplateApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var launch = LaunchCoordinator()

    var body: some Scene {
        WindowGroup {
            OrientationHost(launch: launch)
                .ignoresSafeArea()
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            launch.scenePhaseDidChange(phase)
        }
    }
}
