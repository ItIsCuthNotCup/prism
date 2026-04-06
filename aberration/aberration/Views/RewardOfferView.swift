import SwiftUI

/// Opt-in prompt offering a rewarded ad for an in-game prize.
///
/// Shown after tapping "Play Again" on the game over screen, if the
/// AdPacingEngine determines a reward offer is appropriate.
///
/// Flow: "Watch a short ad to earn a prize!" → [Watch Ad] / [No Thanks]
/// If they watch → RewardChestView plays → reward granted → new game starts.
struct RewardOfferView: View {
    let onWatchAd: () -> Void
    let onDecline: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(appear ? 0.35 : 0)
                .ignoresSafeArea()
                .onTapGesture { onDecline() }

            VStack(spacing: 20) {
                // Chest icon (teaser)
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: 0xF5C542).opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)

                    // Mini chest
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0xD4724A), Color(hex: 0xB85A3A)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 52, height: 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(Color(hex: 0x8B3E2A), lineWidth: 1.5)
                            )
                            .overlay(
                                Circle()
                                    .fill(Color(hex: 0xF5C542))
                                    .frame(width: 10, height: 10)
                            )

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0xC4582A), Color(hex: 0x9E3E1A)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 52, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color(hex: 0x7A2E12), lineWidth: 1.5)
                            )
                    }
                }

                // Title
                Text("Earn a Prize")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x3A3A4A))

                // Description
                Text("Watch a short ad to open a reward chest.\nYou could get an extra life or a hint!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: 0x8D99AE))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                // Watch Ad button
                Button(action: onWatchAd) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                        Text("Watch Ad")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0xD4724A), Color(hex: 0xE8876B)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color(hex: 0xD4724A).opacity(0.3), radius: 8, y: 3)
                    )
                }

                // No thanks
                Button(action: onDecline) {
                    Text("No Thanks")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: 0xAAAAAA))
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.white.opacity(0.95))
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(.white.opacity(0.6), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.12), radius: 30, y: 10)
            )
            .padding(.horizontal, 28)
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appear = true
            }
        }
    }
}
