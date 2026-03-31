//
//  aberrationApp.swift
//  aberration
//
//  Created by Jacob Cuthbertson on 3/29/26.
//

import SwiftUI

@main
struct aberrationApp: App {
    var body: some Scene {
        WindowGroup {
            PrismGameView()
                .onAppear {
                    MusicManager.shared.startTheme()
                }
        }
    }
}
