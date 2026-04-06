//
//  WalkingCatView.swift
//  Chromatose
//
//  A small cat that walks across the top of the game screen,
//  throws up a rainbow, looks around, and walks off.
//  Reuses the same CatSprites assets at a smaller size.
//

import SwiftUI
import Combine

struct WalkingCatView: View {
    /// Bump this to trigger a new walk-across
    var triggerID: Int = 0

    @State private var frames: [UIImage] = []
    @State private var frameIndex: Int = 0
    @State private var isAnimating = false
    @State private var offsetX: CGFloat = -60  // start off-screen left
    @State private var lastTrigger: Int = -1

    private let fps: Double = 12
    private let frameCount = 96
    private let catHeight: CGFloat = 40  // small cat

    var body: some View {
        GeometryReader { geo in
            let screenW = geo.size.width

            Group {
                if let image = frames[safe2: frameIndex] {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: catHeight)
                        .scaleEffect(x: walkingRight ? 1 : -1, y: 1) // flip when returning
                } else {
                    Color.clear.frame(height: catHeight)
                }
            }
            .offset(x: offsetX)
            .onAppear { loadFrames() }
            .onChange(of: triggerID) { _, newVal in
                guard newVal != lastTrigger, !isAnimating else { return }
                lastTrigger = newVal
                startWalk(screenWidth: screenW)
            }
            .onReceive(
                Timer.publish(every: 1.0 / fps, on: .main, in: .common).autoconnect()
            ) { _ in
                guard isAnimating, !frames.isEmpty else { return }
                advanceFrame()
            }
        }
        .frame(height: catHeight)
        .clipped()
    }

    // The sprite animation has 3 phases:
    // 0-23: walking (use these frames for walk-in and walk-out)
    // 24-79: sit + vomit (play once in the middle)
    // 80-95: satisfied sit (play once, then walk out)

    private enum Phase {
        case walkIn, perform, walkOut, done
    }

    @State private var phase: Phase = .done
    @State private var walkFrame: Int = 0

    /// Whether the cat is currently moving right (true) or left/stationary
    private var walkingRight: Bool {
        phase == .walkOut
    }

    private func startWalk(screenWidth: CGFloat) {
        isAnimating = true
        phase = .walkIn
        walkFrame = 0
        frameIndex = 0
        offsetX = -60

        // Walk in to center over ~2 seconds
        let centerX = screenWidth / 2 - 50
        withAnimation(.linear(duration: 2.0)) {
            offsetX = centerX
        }

        // After walk-in, switch to perform phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            phase = .perform
            frameIndex = 24  // start sit/vomit sequence
        }
    }

    private func advanceFrame() {
        switch phase {
        case .walkIn:
            // Cycle through walk frames 0-23
            frameIndex = walkFrame % 24
            walkFrame += 1

        case .perform:
            // Play frames 24-95 (sit, vomit, satisfied)
            if frameIndex < 95 {
                frameIndex += 1
            } else {
                // Done performing, walk out
                phase = .walkOut
                walkFrame = 0
                withAnimation(.linear(duration: 2.0)) {
                    offsetX = 500
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    phase = .done
                    isAnimating = false
                }
            }

        case .walkOut:
            // Cycle walk frames while moving off screen
            frameIndex = walkFrame % 24
            walkFrame += 1

        case .done:
            break
        }
    }

    private func loadFrames() {
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
            }
        }
    }
}

private extension Array {
    subscript(safe2 index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
