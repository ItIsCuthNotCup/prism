import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// Manages interstitial ad loading and presentation.
/// Works with AdScheduler to determine when to show ads.
///
/// Uses GAD-prefixed API names (Google Mobile Ads SDK v11).
@Observable
class AdManager: NSObject {
    static let shared = AdManager()

    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910" // test ad
    #else
    private let adUnitID = "ca-app-pub-1184833535101620/7627017265" // production ad
    #endif

    private(set) var isAdReady = false

    #if canImport(GoogleMobileAds)
    private var interstitialAd: GADInterstitialAd?
    #endif

    private override init() {
        super.init()
        loadAd()
    }

    /// Preload an interstitial ad
    func loadAd() {
        #if canImport(GoogleMobileAds)
        GADInterstitialAd.load(
            withAdUnitID: adUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            if let error = error {
                print("[AdManager] Failed to load ad: \(error.localizedDescription)")
                self?.isAdReady = false
                return
            }
            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
            self?.isAdReady = true
        }
        #else
        print("[AdManager] GoogleMobileAds SDK not installed — ads disabled")
        #endif
    }

    /// Show an interstitial ad if the Fibonacci scheduler says it's time.
    /// Call this at game over.
    func showAdIfScheduled() {
        guard AdScheduler.shared.onGameOver() else { return }
        presentAd()
    }

    /// Force-present the loaded ad (ignores scheduler)
    private func presentAd() {
        #if canImport(GoogleMobileAds)
        guard let ad = interstitialAd,
              let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
              let rootVC = windowScene.windows.first?.rootViewController
        else {
            loadAd()
            return
        }

        ad.present(fromRootViewController: rootVC)
        #endif
    }
}

// MARK: - GADFullScreenContentDelegate

#if canImport(GoogleMobileAds)
extension AdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isAdReady = false
        loadAd()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[AdManager] Failed to present ad: \(error.localizedDescription)")
        isAdReady = false
        loadAd()
    }
}
#endif
