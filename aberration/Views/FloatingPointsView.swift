import SwiftUI

/// Non-blocking floating "+X" text that appears on round complete,
/// rises upward, and fades out. Shows multiplier badge if active.
/// Text color matches the target color that was just scored.
/// Does not block gameplay — purely decorative score feedback.
struct FloatingPointsView: View {
    let amount: Int
    let multiplier: Int
    let trigger: Int
    let color: Color

    @State private var isShowing = false
    @State private var offsetY: CGFloat = 0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        HStack(spacing: 6) {
            if multiplier > 1 {
                Text("×\(multiplier)")
                    .font(.system(size: 14, weight: .black, design: .serif))
                    .foregroundStyle(color)
            }
            Text("+\(amount)")
                .font(.system(size: 28, weight: .black, design: .serif))
                .foregroundStyle(color)
        }
        .shadow(color: .white, radius: 8)
        .shadow(color: .white, radius: 4)
        .offset(y: offsetY)
        .scaleEffect(scale)
        .opacity(isShowing ? 1 : 0)
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newTrigger in
            guard newTrigger > 0 else { return }
            showAnimation()
        }
    }

    private func showAnimation() {
        // Reset
        offsetY = 20
        scale = 0.5
        isShowing = true

        // Pop in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.0
        }

        // Float upward and fade
        withAnimation(.easeOut(duration: 0.8)) {
            offsetY = -60
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            isShowing = false
        }
    }
}
