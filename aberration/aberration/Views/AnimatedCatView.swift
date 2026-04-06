import SwiftUI

/// Frame-by-frame pixel-art cat animation.
/// Uses go_cat_01…go_cat_32 from the asset catalog (4 fps source → looping).
struct AnimatedCatView: View {
    var fps: Double = 8          // playback speed — 8 feels snappy for pixel art
    var height: CGFloat = 140    // display height

    @State private var frame = 1
    private let totalFrames = 32

    var body: some View {
        Image("go_cat_\(String(format: "%02d", frame))")
            .interpolation(.none)       // keep pixel art crisp
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
            .onAppear { startAnimation() }
    }

    private func startAnimation() {
        // Use a repeating timer so the animation loops
        Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { timer in
            frame = (frame % totalFrames) + 1
        }
    }
}
