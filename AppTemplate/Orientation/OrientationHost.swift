import OSLog
import Observation
import SwiftUI

struct OrientationHost: UIViewControllerRepresentable {
    let launch: LaunchCoordinator

    func makeUIViewController(context: Context) -> Presenter {
        Presenter(launch: launch)
    }

    func updateUIViewController(_ presenter: Presenter, context: Context) {}

    final class Presenter: UIViewController {
        private let hostingController: OrientationHostingController
        private var didPresent = false

        init(launch: LaunchCoordinator) {
            hostingController = OrientationHostingController(launch: launch)
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("Use init(launch:)") }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .systemBackground
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard !didPresent, view.window != nil else { return }

            didPresent = true
            present(hostingController, animated: false)
        }
    }
}

private final class OrientationHostingController: UIHostingController<LaunchView> {
    private let logger = Logger(subsystem: AppConfiguration.loggingSubsystem, category: "Orientation")
    private let launch: LaunchCoordinator
    private var orientations: UIInterfaceOrientationMask

    init(launch: LaunchCoordinator) {
        self.launch = launch
        orientations = launch.route.supportedOrientations
        super.init(rootView: LaunchView(launch: launch))
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(launch:)") }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { orientations }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        let scene = presentingViewController?.viewIfLoaded?.window?.windowScene
        if let current = scene?.effectiveGeometry.interfaceOrientation, supports(current) {
            return current
        }
        return [.portrait, .landscapeRight, .landscapeLeft, .portraitUpsideDown]
            .first(where: supports) ?? .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observeSupportedOrientations()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateSceneGeometryIfNeeded()
    }

    private func observeSupportedOrientations() {
        let orientations = withObservationTracking {
            launch.route.supportedOrientations
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.observeSupportedOrientations()
            }
        }
        guard self.orientations != orientations else { return }

        self.orientations = orientations
        setNeedsUpdateOfSupportedInterfaceOrientations()
        updateSceneGeometryIfNeeded()
    }

    private func supports(_ orientation: UIInterfaceOrientation) -> Bool {
        orientation != .unknown && orientations.contains(
            UIInterfaceOrientationMask(rawValue: 1 << orientation.rawValue)
        )
    }

    private func updateSceneGeometryIfNeeded() {
        guard let scene = viewIfLoaded?.window?.windowScene,
              !supports(scene.effectiveGeometry.interfaceOrientation) else { return }

        scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientations)) { [logger] error in
            logger.debug("Orientation update rejected: \(error.localizedDescription, privacy: .private)")
        }
    }
}
