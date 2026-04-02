import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Manages interstitial and rewarded ad loading and presentation.
/// Works with AdPacingEngine for research-based frequency control.
///
/// Uses GAD-prefixed API names (Google Mobile Ads SDK v11).
@Observable
class AdManager: NSObject {
    static let shared = AdManager()

    // MARK: - Ad Unit IDs

    #if DEBUG
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"   // test interstitial
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"       // test rewarded
    #else
    private let interstitialAdUnitID = "ca-app-pub-1184833535101620/7627017265"   // production interstitial
    private let rewardedAdUnitID = "ca-app-pub-1184833535101620/6551708938"       // production rewarded
    #endif

    // MARK: - State

    private(set) var isInterstitialReady = false
    private(set) var isRewardedReady = false

    /// Set to true after a rewarded ad completes successfully
    private(set) var rewardEarned = false

    /// Callback fired when a rewarded ad finishes (success or failure)
    var onRewardedComplete: ((Bool) -> Void)?

    #if canImport(GoogleMobileAds)
    private var interstitialAd: GADInterstitialAd?
    private var rewardedAd: GADRewardedAd?
    #endif

    // MARK: - Init

    private override init() {
        super.init()
        loadInterstitial()
        loadRewarded()
    }

    // MARK: - Interstitial

    func loadInterstitial() {
        #if canImport(GoogleMobileAds)
        GADInterstitialAd.load(
            withAdUnitID: interstitialAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            if let error = error {
                print("[AdManager] Failed to load interstitial: \(error.localizedDescription)")
                self?.isInterstitialReady = false
                return
            }
            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
            self?.isInterstitialReady = true
        }
        #else
        print("[AdManager] GoogleMobileAds SDK not installed — ads disabled")
        #endif
    }

    /// Show an interstitial if the pacing engine says it's time.
    /// Call this at game over / play again.
    func showInterstitialIfScheduled() {
        guard AdPacingEngine.shared.onGameOver() else { return }
        presentInterstitial()
    }

    private func presentInterstitial() {
        #if canImport(GoogleMobileAds)
        guard let ad = interstitialAd,
              let rootVC = Self.rootViewController
        else {
            loadInterstitial()
            return
        }
        ad.present(fromRootViewController: rootVC)
        #endif
    }

    // MARK: - Rewarded

    func loadRewarded() {
        #if canImport(GoogleMobileAds)
        GADRewardedAd.load(
            withAdUnitID: rewardedAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            if let error = error {
                print("[AdManager] Failed to load rewarded: \(error.localizedDescription)")
                self?.isRewardedReady = false
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            self?.isRewardedReady = true
        }
        #else
        print("[AdManager] GoogleMobileAds SDK not installed — rewarded ads disabled")
        #endif
    }

    /// Whether the pacing engine says we should offer a reward this game over
    var shouldOfferReward: Bool {
        AdPacingEngine.shared.shouldOfferReward()
    }

    /// Present a rewarded ad. Call only after user opts in.
    /// Completion fires with true if reward earned, false if cancelled/failed.
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        onRewardedComplete = completion
        rewardEarned = false

        #if canImport(GoogleMobileAds)
        guard let ad = rewardedAd,
              let rootVC = Self.rootViewController
        else {
            completion(false)
            loadRewarded()
            return
        }

        ad.present(fromRootViewController: rootVC) { [weak self] in
            // User earned the reward
            self?.rewardEarned = true
            AdPacingEngine.shared.onRewardedAdShown()
        }
        #else
        // No SDK — simulate reward for development
        rewardEarned = true
        AdPacingEngine.shared.onRewardedAdShown()
        completion(true)
        #endif
    }

    /// Call when user declines the reward offer
    func declineReward() {
        AdPacingEngine.shared.onRewardDeclined()
    }

    // MARK: - Helpers

    private static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .rootViewController
    }

    // MARK: - Legacy compatibility

    /// Old API — redirects to new pacing engine
    func showAdIfScheduled() {
        showInterstitialIfScheduled()
    }
}

// MARK: - GADFullScreenContentDelegate

#if canImport(GoogleMobileAds)
extension AdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        // Determine which ad type dismissed
        if ad === interstitialAd as? GADFullScreenPresentingAd {
            isInterstitialReady = false
            loadInterstitial()
        } else {
            // Rewarded ad dismissed
            isRewardedReady = false
            let earned = rewardEarned
            onRewardedComplete?(earned)
            onRewardedComplete = nil
            loadRewarded()
        }
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[AdManager] Failed to present ad: \(error.localizedDescription)")

        if ad === interstitialAd as? GADFullScreenPresentingAd {
            isInterstitialReady = false
            loadInterstitial()
        } else {
            isRewardedReady = false
            onRewardedComplete?(false)
            onRewardedComplete = nil
            loadRewarded()
        }
    }
}
#endif
