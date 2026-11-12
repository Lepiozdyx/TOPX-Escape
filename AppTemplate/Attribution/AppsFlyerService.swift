import AppsFlyerLib
import AppTrackingTransparency
import Foundation
import OSLog
import SwiftUI

@MainActor
final class AppsFlyerService: NSObject, AppsFlyerLibDelegate {
    private let defaults: UserDefaults
    private let sdk = AppsFlyerLib.shared()
    private let logger = Logger(subsystem: AppConfiguration.loggingSubsystem, category: "AppsFlyer")

    private var isActive = false
    private var didFinishTrackingAuthorization = false
    private var didStartForegroundSession = false
    private var didReceiveConversion = false
    private var conversionWaiter: CheckedContinuation<AttributionData, Never>?
    private var conversionTimeout: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()

        #if DEBUG
        sdk.isDebug = true
        #endif
        sdk.initialize(devKey: AppConfiguration.appsFlyerDevKey, appId: AppConfiguration.appleAppID)
        sdk.delegate = self
        sdk.registerSessionReadyListener { [weak self] in
            Task { @MainActor in
                self?.startSessionIfReady()
            }
        }
    }

    private var snapshot: AttributionData {
        let storedParameters = defaults.string(forKey: "subParams") ?? ""
        let parameters = storedParameters.split(separator: "&").compactMap { parameter -> URLQueryItem? in
            let pair = parameter.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard pair.count == 2 else { return nil }

            let value = String(pair[1])
            return URLQueryItem(name: String(pair[0]), value: value.removingPercentEncoding ?? value)
        }
        return AttributionData(
            campaignParameters: parameters,
            appsFlyerID: defaults.string(forKey: "afid") ?? ""
        )
    }

    func scenePhaseDidChange(_ phase: ScenePhase) {
        isActive = phase == .active
        if phase == .background {
            didStartForegroundSession = false
        }
        startSessionIfReady()
    }

    func finishTrackingAuthorization() async {
        if isActive, ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        didFinishTrackingAuthorization = true
        startSessionIfReady()
    }

    func waitForInitialConversion() async -> AttributionData {
        guard !didReceiveConversion else { return snapshot }

        return await withCheckedContinuation { continuation in
            conversionWaiter = continuation
            conversionTimeout = Task { [weak self] in
                do {
                    try await Task.sleep(for: .seconds(5))
                    self?.finishConversionWait()
                } catch {
                    // The conversion callback ended the wait.
                }
            }
        }
    }

    nonisolated func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        let campaign = conversionInfo["campaign"] as? String
        Task { @MainActor in
            self.saveCampaign(campaign)
            self.didReceiveConversion = true
            self.finishConversionWait()
        }
    }

    nonisolated func onConversionDataFail(_ error: any Error) {
        logger.debug("Conversion data unavailable: \(error.localizedDescription, privacy: .private)")
    }

    private func startSessionIfReady() {
        guard isActive, didFinishTrackingAuthorization, !didStartForegroundSession,
              sdk.isSessionReady() else { return }

        didStartForegroundSession = true
        sdk.start()
        defaults.set(sdk.getAppsFlyerUID(), forKey: "afid")
    }

    private func saveCampaign(_ campaign: String?) {
        guard let parts = campaign?.split(separator: "_"), parts.count > 1 else { return }

        let parameters = parts.enumerated().map { index, part in
            URLQueryItem(name: "sub\(index + 1)", value: String(part))
        }
        defaults.set(AttributionData.encode(parameters), forKey: "subParams")
    }

    private func finishConversionWait() {
        conversionTimeout?.cancel()
        conversionTimeout = nil
        let waiter = conversionWaiter
        conversionWaiter = nil
        waiter?.resume(returning: snapshot)
    }
}
