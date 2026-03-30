//
//  CatMascotView.swift
//  aberration
//
//  Animated sprite: pixel-art cat walks on, sits, throws up rainbow.
//  96 frames at 12 fps from CatSprites bundle folder.
//

import SwiftUI
import Combine

struct CatMascotView: View {
    /// Set true to kick off the animation
    var playing: Bool = true

    @State private var frameIndex: Int = 0
    @State private var frames: [UIImage] = []

    private let fps: Double = 12
    private let frameCount = 96

    var body: some View {
        Group {
            if let image = frames[safe: frameIndex] {
                Image(uiImage: image)
                    .interpolation(.none)   // keep pixel-art crisp
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.clear
            }
        }
        .onAppear { loadFrames() }
        .onReceive(
            Timer.publish(every: 1.0 / fps, on: .main, in: .common)
                .autoconnect()
        ) { _ in
            guard playing, !frames.isEmpty else { return }
            if frameIndex < frames.count - 1 {
                frameIndex += 1
            }
            // Stays on last frame after finishing (cat sitting satisfied)
        }
    }

    private func loadFrames() {
        // Load on background thread to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async {
            var loaded: [UIImage] = []
            for i in 0..<frameCount {
                let name = String(format: "cat_%04d", i)
                if let img = UIImage(named: name) {
                    loaded.append(img)
                }
            }
            DispatchQueue.main.async {
                frames = loaded
                frameIndex = 0
            }
        }
    }
}

// Safe array subscript
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
