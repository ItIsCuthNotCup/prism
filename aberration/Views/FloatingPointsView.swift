import SwiftUI

/// Non-blocking floating "+X" text that appears on round complete,
/// rises upward, and fades out. Shows multiplier badge if active.
/// Does not block gameplay — purely decorative score feedback.
struct FloatingPointsView: View {
    let amount: Int
    let multiplier: Int
    let trigger: Int
    let combo: String?

    @State private var localTrigger: Int = 0
    @State private var isShowing = false
    @State private var offsetY: CGFloat = 0

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                if multiplier > 1 {
                    Text("×\(multiplier)")
                        .font(.system(size: 14, weight: .black, design: .serif))
                        .foregroundStyle(Color(hex: 0xF59E0B))
                }
                Text("+\(amount)")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(multiplier > 1 ? Color(hex: 0xF59E0B) : Color(hex: 0x2A9D8F))
            }

            if let combo {
                Text(combo)
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundStyle(Color(hex: 0x2A9D8F))
                    .tracking(1)
            }
        }
        .shadow(color: .white, radius: 8)
        .shadow(color: .white, radius: 4)
        .offset(y: offsetY)
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
        isShowing = true

        // Float upward and fade
        withAnimation(.easeOut(duration: 0.8)) {
            offsetY = -60
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            isShowing = false
        }
    }
}
