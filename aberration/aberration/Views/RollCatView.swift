import SwiftUI

/// Roll-over cat celebration: pops up from below, plays a roll-over animation,
/// then drops back down under the screen.
/// Uses roll_cat_01…roll_cat_19 from the asset catalog.
struct RollCatView: View {
    var onComplete: () -> Void = {}

    private let totalFrames = 19
    private let fps: Double = 12

    @State private var frame = 1
    @State private var isVisible = false
    @State private var timer: Timer?

    var body: some View {
        VStack {
            Spacer()

            Image("roll_cat_\(String(format: "%02d", frame))")
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 90)
                .offset(y: isVisible ? 0 : 180)
                .opacity(isVisible ? 1 : 0)
                .padding(.bottom, 30)
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
        SoundManager.shared.playRollCat()

        // Pop up from below
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            isVisible = true
        }

        // Start sprite animation after the pop-up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            frame = 1
            timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { t in
                if frame < totalFrames {
                    frame += 1
                } else {
                    // Roll complete — drop back down
                    t.invalidate()
                    timer = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeIn(duration: 0.35)) {
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            onComplete()
                        }
                    }
                }
            }
        }
    }
}
