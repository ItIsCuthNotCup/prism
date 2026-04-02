import SwiftUI

/// Stretch cat celebration: cat appears centre-bottom, plays a stretch animation
/// (frames 1-11), then switches to a looping run cycle (frames 12-19) and slides
/// off-screen to the right — similar to ChaseCatView.
/// Uses stretch_cat_01…stretch_cat_19 from the asset catalog.
struct StretchCatView: View {
    var onComplete: () -> Void = {}

    // Sprite config
    private let stretchStart = 1
    private let stretchEnd = 11       // last stretch frame
    private let runStart = 12
    private let runEnd = 19           // last run frame
    private let stretchFps: Double = 10
    private let runFps: Double = 12

    @State private var frame = 1
    @State private var offsetX: CGFloat = 0
    @State private var isVisible = false
    @State private var timer: Timer?
    @State private var started = false

    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()

                Image("stretch_cat_\(String(format: "%02d", frame))")
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .offset(x: offsetX)
                    .opacity(isVisible ? 1 : 0)
                    .padding(.bottom, 40)
            }
            .allowsHitTesting(false)
            .onAppear {
                guard !started else { return }
                started = true
                startSequence(screenWidth: geo.size.width)
            }
        }
    }

    private func startSequence(screenWidth: CGFloat) {
        // Sound
        SoundManager.shared.playStretchCat()

        // Fade in quickly
        withAnimation(.easeIn(duration: 0.25)) {
            isVisible = true
        }

        // Phase 1: play stretch frames (stationary, centre of screen)
        frame = stretchStart
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / stretchFps, repeats: true) { t in
            if frame < stretchEnd {
                frame += 1
            } else {
                // Stretch done → switch to run phase
                t.invalidate()
                startRunPhase(screenWidth: screenWidth)
            }
        }
    }

    private func startRunPhase(screenWidth: CGFloat) {
        // Switch to first run frame
        frame = runStart

        // Loop run cycle
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / runFps, repeats: true) { _ in
            frame = frame < runEnd ? frame + 1 : runStart
        }

        // Slide off-screen right
        let duration: Double = 1.6
        withAnimation(.easeIn(duration: duration)) {
            offsetX = screenWidth + 150
        }

        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            timer?.invalidate()
            timer = nil
            onComplete()
        }
    }
}
