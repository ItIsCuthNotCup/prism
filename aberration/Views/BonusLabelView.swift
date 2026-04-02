import SwiftUI

/// Floating bonus label that appears on round complete.
/// Each bonus type has its own color, icon, and animation feel:
///   - Perfect Mix: pink sparkle, pops big
///   - Efficient: green check, smooth slide
///   - Clean Streak: lavender flame, steady rise
///   - Speed Demon: yellow bolt, fast zip
///   - Untouchable: red shield, dramatic slam + shake
struct BonusLabelView: View {
    let bonus: GameState.EarnedBonus?
    let trigger: Int

    @State private var isShowing = false
    @State private var offsetY: CGFloat = 0
    @State private var scale: CGFloat = 0.5
    @State private var glowOpacity: Double = 0
    @State private var shakeX: CGFloat = 0

    var body: some View {
        if let bonus {
            let bonusColor = Color(hex: bonus.type.hexColor)

            HStack(spacing: 6) {
                Image(systemName: bonus.type.sfIcon)
                    .font(.system(size: 14, weight: .bold))

                Text(bonus.type.label)
                    .font(.system(size: 16, weight: .black, design: .serif))

                if bonus.points > 0 {
                    Text("+\(bonus.points)")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                }

                if bonus.isMultiplier {
                    Text("5×")
                        .font(.system(size: 18, weight: .black, design: .serif))
                }
            }
            .foregroundStyle(Color(hex: 0x2A2A2A))
            .shadow(color: bonusColor.opacity(glowOpacity * 0.5), radius: 8)
            .shadow(color: .white, radius: 4)
            .offset(x: shakeX, y: offsetY)
            .scaleEffect(scale)
            .opacity(isShowing ? 1 : 0)
            .allowsHitTesting(false)
            .onChange(of: trigger) { _, newTrigger in
                guard newTrigger > 0 else { return }
                animate(for: bonus.type)
            }
        }
    }

    // MARK: - Per-Type Animations

    private func animate(for type: GameState.BonusType) {
        // Reset
        offsetY = 40
        scale = 0.5
        glowOpacity = 0
        shakeX = 0
        isShowing = false

        switch type {
        case .untouchable:
            animateUntouchable()
        case .perfectBlend:
            animatePerfectBlend()
        case .speedDemon:
            animateSpeedDemon()
        case .efficient:
            animateEfficient()
        case .cleanStreak:
            animateCleanStreak()
        }
    }

    /// Untouchable: dramatic slam from above, shake, persistent glow
    private func animateUntouchable() {
        offsetY = -80
        scale = 1.5
        isShowing = true

        // Slam down
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
            offsetY = 0
            scale = 1.2
        }

        // Glow pulse
        withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
            glowOpacity = 0.8
        }

        // Shake
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let shakes: [CGFloat] = [8, -8, 6, -6, 4, -4, 2, -2, 0]
            for (i, x) in shakes.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                    withAnimation(.linear(duration: 0.04)) { shakeX = x }
                }
            }
        }

        // Settle and fade
        withAnimation(.easeOut(duration: 0.6).delay(1.2)) {
            scale = 1.0
            glowOpacity = 0.3
        }
        withAnimation(.easeIn(duration: 0.5).delay(2.0)) {
            isShowing = false
        }
    }

    /// Perfect Blend: pop big with sparkle, bounce
    private func animatePerfectBlend() {
        isShowing = true
        offsetY = 20

        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            scale = 1.3
            offsetY = -10
        }

        withAnimation(.easeIn(duration: 0.2).delay(0.1)) {
            glowOpacity = 0.6
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.3)) {
            scale = 1.0
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
            offsetY = -50
        }
        withAnimation(.easeIn(duration: 0.4).delay(1.0)) {
            isShowing = false
        }
    }

    /// Speed Demon: fast zip from right, brief hold
    private func animateSpeedDemon() {
        offsetY = 0
        scale = 1.0
        shakeX = 120
        isShowing = true

        withAnimation(.easeOut(duration: 0.15)) {
            shakeX = 0
        }

        withAnimation(.easeIn(duration: 0.2).delay(0.1)) {
            glowOpacity = 0.5
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            offsetY = -40
        }
        withAnimation(.easeIn(duration: 0.3).delay(0.8)) {
            isShowing = false
        }
    }

    /// Efficient: smooth slide up, calm
    private func animateEfficient() {
        isShowing = true
        offsetY = 30

        withAnimation(.easeOut(duration: 0.4)) {
            scale = 1.0
            offsetY = -10
        }

        withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
            glowOpacity = 0.4
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
            offsetY = -50
        }
        withAnimation(.easeIn(duration: 0.4).delay(0.9)) {
            isShowing = false
        }
    }

    /// Clean Streak: steady rise with pulse
    private func animateCleanStreak() {
        isShowing = true
        offsetY = 25

        withAnimation(.easeOut(duration: 0.35)) {
            scale = 1.05
            offsetY = -5
        }

        withAnimation(.easeInOut(duration: 0.4).delay(0.2)) {
            glowOpacity = 0.5
        }

        withAnimation(.easeOut(duration: 0.7).delay(0.7)) {
            offsetY = -45
            scale = 0.9
        }
        withAnimation(.easeIn(duration: 0.4).delay(1.0)) {
            isShowing = false
        }
    }
}
