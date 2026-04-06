import SwiftUI

/// Binoculars cat celebration: pops up from below, looks left through binoculars,
/// turns to look at the camera, then naturally sinks back down (sink is baked into
/// the sprite frames, so no SwiftUI drop animation is needed).
/// Uses bino_cat_01…bino_cat_18 from the asset catalog.
struct BinocularsCatView: View {
    var onComplete: () -> Void = {}

    private let totalFrames = 18
    private let fps: Double = 10

    @State private var frame = 1
    @State private var isVisible = false
    @State private var timer: Timer?

    var body: some View {
        VStack {
            Spacer()

            Image("bino_cat_\(String(format: "%02d", frame))")
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 140)
                .offset(y: isVisible ? 0 : 180)
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
        SoundManager.shared.playBinocularsCat()

        // Pop up from below
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            isVisible = true
        }

        // Start sprite animation after the pop-up finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            frame = 1
            timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { t in
                if frame < totalFrames {
                    frame += 1
                } else {
                    // Last frames show the cat sinking — animation done
                    t.invalidate()
                    timer = nil
                    // Brief pause then notify parent
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onComplete()
                    }
                }
            }
        }
    }
}
