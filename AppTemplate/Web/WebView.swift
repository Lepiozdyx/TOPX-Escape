import OSLog
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.bounces = true
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private static let inAppSchemes: Set<String> = ["http", "https", "about", "data", "file"]
        private let logger = Logger(subsystem: AppConfiguration.loggingSubsystem, category: "WebView")

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url,
                  let scheme = url.scheme?.lowercased(),
                  !Self.inAppSchemes.contains(scheme) else { return .allow }

            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return .cancel
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            webView.load(navigationAction.request)
            return nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
            logger.debug("Navigation failed: \(error.localizedDescription, privacy: .private)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
            logger.debug("Provisional navigation failed: \(error.localizedDescription, privacy: .private)")
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping @MainActor () -> Void
        ) {
            guard let presenter = dialogPresenter(for: webView) else {
                completionHandler()
                return
            }

            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            presenter.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping @MainActor (Bool) -> Void
        ) {
            guard let presenter = dialogPresenter(for: webView) else {
                completionHandler(false)
                return
            }

            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            presenter.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping @MainActor (String?) -> Void
        ) {
            guard let presenter = dialogPresenter(for: webView) else {
                completionHandler(nil)
                return
            }

            let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            alert.addTextField { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
                completionHandler(alert?.textFields?.first?.text ?? defaultText)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
            presenter.present(alert, animated: true)
        }

        private func dialogPresenter(for webView: WKWebView) -> UIViewController? {
            guard let window = webView.window, var presenter = window.rootViewController else { return nil }
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            guard presenter.viewIfLoaded?.window === window,
                  !presenter.isBeingPresented, !presenter.isBeingDismissed,
                  !(presenter is UIAlertController) else { return nil }
            return presenter
        }
    }
}
