//
//  aberrationApp.swift
//  aberration
//
//  Created by Jacob Cuthbertson on 3/29/26.
//

import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct aberrationApp: App {
    init() {
        #if canImport(GoogleMobileAds)
        // Initialize the Google Mobile Ads SDK (v11 API)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        #endif
        // Preload the first interstitial ad (no-op if SDK absent)
        _ = AdManager.shared
    }

    var body: some Scene {
        WindowGroup {
            PrismGameView()
                .onAppear {
                    MusicManager.shared.startTheme()
                }
        }
    }
}
