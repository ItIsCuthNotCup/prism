import SwiftUI

/// Floating bonus label that appears below the points on round complete.
/// Shows messages like "Perfect Blend!", "Speed Demon!", etc.
/// Appears slightly delayed after the points, fades out.
struct BonusLabelView: View {
    let message: String
    let trigger: Int

    @State private var isShowing = false
    @State private var offsetY: CGFloat = 0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .bold, design: .serif))
            .foregroundStyle(Color(hex: 0xF5C542))
            .shadow(color: Color(hex: 0xF5C542).opacity(0.4), radius: 6)
            .shadow(color: .white, radius: 4)
            .offset(y: offsetY)
            .scaleEffect(scale)
            .opacity(isShowing ? 1 : 0)
            .allowsHitTesting(false)
            .onChange(of: trigger) { _, newTrigger in
                guard newTrigger > 0, !message.isEmpty else { return }
                showAnimation()
            }
    }

    private func showAnimation() {
        // Reset
        offsetY = 40
        scale = 0.5
        isShowing = false

        // Slight delay after the points appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isShowing = true

            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }

            withAnimation(.easeOut(duration: 0.8)) {
                offsetY = -20
            }

            withAnimation(.easeIn(duration: 0.4).delay(0.6)) {
                isShowing = false
            }
        }
    }
}
