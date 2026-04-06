import SwiftUI

/// Pixel-art celebration cat that pops up from the bottom of the screen,
/// plays a clap animation, then drops back down.
/// Uses cel_cat_01…cel_cat_41 from the asset catalog.
struct CelebrationCatView: View {
    /// Called when the full animation (pop up + clap + drop) finishes.
    var onComplete: () -> Void = {}

    // Only play the clap+sparkles portion (frames 8–30 of the 41-frame set)
    private let startFrame = 8
    private let endFrame = 30
    private let fps: Double = 14

    @State private var frame = 8
    @State private var isVisible = false
    @State private var timer: Timer?

    var body: some View {
        VStack {
            Spacer()

            Image("cel_cat_\(String(format: "%02d", frame))")
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 120)
                .offset(y: isVisible ? 0 : 160)
                .opacity(isVisible ? 1 : 0)
        }
        .allowsHitTesting(false)
        .onAppear {
            startSequence()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startSequence() {
        // Sound
        SoundManager.shared.playClappingCat()

        // Pop up from below
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isVisible = true
        }

        // Start frame animation
        frame = startFrame
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { t in
            if frame < endFrame {
                frame += 1
            } else {
                // Animation complete — drop back down
                t.invalidate()
                timer = nil
                withAnimation(.easeIn(duration: 0.3)) {
                    isVisible = false
                }
                // Notify parent after drop animation finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    onComplete()
                }
            }
        }
    }
}
