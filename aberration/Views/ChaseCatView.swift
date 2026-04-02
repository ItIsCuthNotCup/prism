import SwiftUI

/// Cat-chasing-mouse celebration that runs from off-screen right to off-screen left.
/// Uses chase_cat_01…chase_cat_08 (a looping run cycle with mouse + cat together).
/// SwiftUI handles the horizontal traversal; the sprite frames handle the gait animation.
struct ChaseCatView: View {
    var onComplete: () -> Void = {}

    private let totalFrames = 8
    private let fps: Double = 12

    @State private var frame = 1
    @State private var offsetX: CGFloat = 0
    @State private var timer: Timer?
    @State private var started = false

    var body: some View {
        GeometryReader { geo in
            VStack {
                Spacer()

                Image("chase_cat_\(String(format: "%02d", frame))")
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                    .offset(x: offsetX)
                    .padding(.bottom, 40)
            }
            .allowsHitTesting(false)
            .onAppear {
                guard !started else { return }
                started = true
                startChase(screenWidth: geo.size.width)
            }
        }
    }

    private func startChase(screenWidth: CGFloat) {
        // Sound
        SoundManager.shared.playChaseCat()

        // Start off-screen right
        offsetX = screenWidth + 100

        // Start looping run cycle
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { _ in
            frame = (frame % totalFrames) + 1
        }

        // Slide from right to left across the screen
        let duration: Double = 2.0
        withAnimation(.linear(duration: duration)) {
            offsetX = -300  // off-screen left
        }

        // Clean up after traversal completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            timer?.invalidate()
            timer = nil
            onComplete()
        }
    }
}
