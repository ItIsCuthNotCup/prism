import SwiftUI

/// Animated reward chest that opens to reveal a life or hint token.
///
/// Flow: chest appears → shakes → lid opens → reward icon rises out with glow → label
/// Uses SF Symbols as placeholders (user will supply custom icons later).
struct RewardChestView: View {
    let reward: GameState.RewardType
    let onDismiss: () -> Void

    @State private var phase: Phase = .waiting
    @State private var lidAngle: Double = 0
    @State private var rewardOffset: CGFloat = 0
    @State private var rewardOpacity: Double = 0
    @State private var rewardScale: CGFloat = 0.3
    @State private var glowOpacity: Double = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var labelOpacity: Double = 0
    @State private var overlayOpacity: Double = 0

    private enum Phase {
        case waiting, shaking, opening, revealed
    }

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.4 * overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    if phase == .revealed { onDismiss() }
                }

            VStack(spacing: 16) {
                Spacer()

                // Chest + reward stack
                ZStack {
                    // Glow behind reward
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [rewardGlowColor.opacity(0.6), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .opacity(glowOpacity)
                        .offset(y: -40)

                    // Reward icon (rises out of chest)
                    rewardIcon
                        .font(.system(size: 56))
                        .foregroundStyle(rewardIconGradient)
                        .offset(y: -40 + rewardOffset)
                        .opacity(rewardOpacity)
                        .scaleEffect(rewardScale)

                    // Chest body
                    VStack(spacing: 0) {
                        // Lid (rotates open)
                        chestLid
                            .rotation3DEffect(.degrees(lidAngle), axis: (x: 1, y: 0, z: 0), anchor: .bottom)

                        // Base
                        chestBase
                    }
                    .offset(x: shakeOffset)
                }

                // Reward label
                VStack(spacing: 4) {
                    Text(rewardTitle)
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(Color(hex: 0x3A3A4A))

                    Text(rewardSubtitle)
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(Color(hex: 0x8D99AE))
                }
                .opacity(labelOpacity)
                .padding(.top, 8)

                // Tap to continue
                if phase == .revealed {
                    Text("Tap anywhere to continue")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: 0xBBBBBB))
                        .padding(.top, 8)
                        .transition(.opacity)
                }

                Spacer()
            }
        }
        .onAppear { startSequence() }
    }

    // MARK: - Chest Drawing

    private var chestLid: some View {
        ZStack {
            // Lid shape
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xD4724A), Color(hex: 0xB85A3A)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 90, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(hex: 0x8B3E2A), lineWidth: 2)
                )

            // Lock/clasp
            Circle()
                .fill(Color(hex: 0xF5C542))
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .strokeBorder(Color(hex: 0xD4A020), lineWidth: 1.5)
                )
        }
    }

    private var chestBase: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0xC4582A), Color(hex: 0x9E3E1A)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 90, height: 50)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color(hex: 0x7A2E12), lineWidth: 2)
            )
            .overlay(
                // Metal band
                Rectangle()
                    .fill(Color(hex: 0xF5C542).opacity(0.4))
                    .frame(height: 3)
                    .offset(y: -8)
            )
    }

    // MARK: - Reward Display

    @ViewBuilder
    private var rewardIcon: some View {
        switch reward {
        case .extraLife:
            // Teardrop / heart for life — using SF Symbol placeholder
            Image(systemName: "heart.fill")
        case .hintToken:
            // Book for hint
            Image(systemName: "book.fill")
        }
    }

    private var rewardGlowColor: Color {
        switch reward {
        case .extraLife: return Color(hex: 0xE8876B)
        case .hintToken: return Color(hex: 0x7BB3E0)
        }
    }

    private var rewardIconGradient: some ShapeStyle {
        switch reward {
        case .extraLife:
            return LinearGradient(
                colors: [Color(hex: 0xE8876B), Color(hex: 0xD4724A)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .hintToken:
            return LinearGradient(
                colors: [Color(hex: 0x7BB3E0), Color(hex: 0x5A9BC7)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var rewardTitle: String {
        switch reward {
        case .extraLife: return "+1 Life"
        case .hintToken: return "+1 Hint"
        }
    }

    private var rewardSubtitle: String {
        switch reward {
        case .extraLife: return "Retry a round when you run out of moves"
        case .hintToken: return "Highlights the best pair to blend"
        }
    }

    // MARK: - Animation Sequence

    private func startSequence() {
        // Fade in
        withAnimation(.easeIn(duration: 0.3)) {
            overlayOpacity = 1
        }

        // Phase 1: Shake (after 0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            phase = .shaking
            shakeAnimation()
        }

        // Phase 2: Open lid (after shaking)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            phase = .opening
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                lidAngle = -120
            }
            SoundManager.shared.playMilestone()
        }

        // Phase 3: Reward rises (after lid opens)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                rewardOffset = -80
                rewardOpacity = 1
                rewardScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.4)) {
                glowOpacity = 1
            }
        }

        // Phase 4: Label appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            phase = .revealed
            withAnimation(.easeOut(duration: 0.3)) {
                labelOpacity = 1
            }
        }
    }

    private func shakeAnimation() {
        let shakes = [CGFloat(4), -4, 6, -6, 8, -8, 5, -5, 3, -3, 0]
        for (i, offset) in shakes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                withAnimation(.linear(duration: 0.06)) {
                    shakeOffset = offset
                }
            }
        }
    }
}
