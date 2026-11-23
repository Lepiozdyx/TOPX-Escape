import SwiftUI

enum LaunchRoute {
    case loading
    case native
    case web(URL)

    var supportedOrientations: UIInterfaceOrientationMask {
        switch self {
        case .loading, .native: AppConfiguration.nativeOrientation
        case .web: .all
        }
    }
}

@MainActor
@Observable
final class LaunchCoordinator {
    private(set) var route: LaunchRoute = .native
    private(set) var scenePhase: ScenePhase = .background
//
//    private let attribution = AppsFlyerService()
//    private let webRouteResolver = WebRouteResolver()
//    private var didBeginLaunch = false

    func scenePhaseDidChange(_ phase: ScenePhase) {
//        scenePhase = phase
//        attribution.scenePhaseDidChange(phase)
//        guard phase == .active, !didBeginLaunch else { return }
//
//        didBeginLaunch = true
//        Task {
//            await attribution.finishTrackingAuthorization()
//            let initialAttribution = await attribution.waitForInitialConversion()
//
//            if let url = await webRouteResolver.resolve(
//                initialURL: AppConfiguration.initialURL,
//                attribution: initialAttribution
//            ) {
//                route = .web(url)
//            } else {
//                route = .native
//            }
//        }
    }
}
