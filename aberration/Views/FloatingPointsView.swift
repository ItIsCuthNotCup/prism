import SwiftUI

/// Score feedback animation on round complete.
///
/// Both bonus and total score appear in the target color.
/// They combine, then zoom upward toward the score counter,
/// shrinking and fading as if absorbed into it.
struct FloatingPointsView: View {
    let amount: Int
    let multiplier: Int
    let trigger: Int
    let color: Color
    let bonus: GameState.EarnedBonus?
    let bonusTrigger: Int

    // Phase states
    @State private var bonusOffsetY: CGFloat = -20
    @State private var bonusOpacity: Double = 0
    @State private var bonusScale: CGFloat = 0.7

    @State private var totalScale: CGFloat = 0.5
    @State private var totalOpacity: Double = 0
    @State private var totalOffsetY: CGFloat = 10

    // Merge + zoom-to-score states
    @State private var mergedScale: CGFloat = 1.0
    @State private var groupOffsetY: CGFloat = 0
    @State private var groupScale: CGFloat = 1.0
    @State private var groupOpacity: Double = 1.0

    var body: some View {
        VStack(spacing: 6) {
            // Bonus line (slides in first, then collapses into total)
            if let bonus, bonus.points > 0 || bonus.isMultiplier {
                HStack(spacing: 4) {
                    Image(systemName: bonus.type.sfIcon)
                        .font(.system(size: 12, weight: .bold))
                    Text(bonus.type.label)
                        .font(.system(size: 14, weight: .bold, design: .serif))
                    if bonus.points > 0 {
                        Text("+\(bonus.points)")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                    }
                    if bonus.isMultiplier {
                        Text("5×")
                            .font(.system(size: 15, weight: .black, design: .serif))
                    }
                }
                .foregroundStyle(color)
                .shadow(color: .white, radius: 6)
                .shadow(color: .white, radius: 3)
                .offset(y: bonusOffsetY)
                .opacity(bonusOpacity)
                .scaleEffect(bonusScale)
            }

            // Total score line
            HStack(spacing: 4) {
                if multiplier > 1 {
                    Text("×\(multiplier)")
                        .font(.system(size: 13, weight: .black, design: .serif))
                        .foregroundStyle(color)
                }
                Text("+\(amount)")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(color)
            }
            .shadow(color: .white, radius: 8)
            .shadow(color: .white, radius: 4)
            .scaleEffect(totalScale * mergedScale)
            .opacity(totalOpacity)
            .offset(y: totalOffsetY)
        }
        // Group transform: zoom toward score counter (upward + shrink + fade)
        .offset(y: groupOffsetY)
        .scaleEffect(groupScale)
        .opacity(groupOpacity)
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newTrigger in
            guard newTrigger > 0 else { return }
            runAnimation()
        }
    }

    private func runAnimation() {
        let hasBonus = bonus != nil && (bonus!.points > 0 || bonus!.isMultiplier)

        // Reset all state
        bonusOffsetY = -20
        bonusOpacity = 0
        bonusScale = 0.7
        totalScale = 0.5
        totalOpacity = 0
        totalOffsetY = 10
        mergedScale = 1.0
        groupOffsetY = 0
        groupScale = 1.0
        groupOpacity = 1.0

        if hasBonus {
            // Phase 1: Show bonus label (drops in from above)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                bonusOpacity = 1
                bonusOffsetY = 0
                bonusScale = 1.0
            }

            // Phase 2: After a beat, show total below
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    totalOpacity = 1
                    totalScale = 1.0
                    totalOffsetY = 0
                }
            }

            // Phase 3: Bonus collapses into total
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeIn(duration: 0.2)) {
                    bonusOpacity = 0
                    bonusScale = 0.5
                    bonusOffsetY = 20
                }
                // Total pulses bigger when bonus merges in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    mergedScale = 1.2
                }
            }

            // Phase 4: Total settles back
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    mergedScale = 1.0
                }
            }

            // Phase 5: Zoom toward score counter — fly up, shrink, disappear
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeIn(duration: 0.35)) {
                    groupOffsetY = -120
                    groupScale = 0.3
                    groupOpacity = 0
                }
            }
        } else {
            // No bonus — simple pop in, then zoom to score
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                totalOpacity = 1
                totalScale = 1.0
                totalOffsetY = 0
            }

            // Hold briefly, then zoom toward score counter
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.35)) {
                    groupOffsetY = -120
                    groupScale = 0.3
                    groupOpacity = 0
                }
            }
        }
    }
}
