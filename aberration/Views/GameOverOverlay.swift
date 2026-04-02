import SwiftUI

struct GameOverOverlay: View {
    let score: Int
    let round: Int
    let highScore: Int
    let bestRound: Int
    let emptySpaces: Int
    let targetColor: PrismColor?
    let closestColor: PrismColor?
    let closestDistance: Int
    let totalBlends: Int
    let lives: Int
    let hintTokens: Int
    let onUseLife: () -> Void
    let onPlayAgain: () -> Void

    @State private var showShareSheet = false
    @State private var showAchievements = false

    private var isNewHighScore: Bool { score >= highScore && score > 0 }

    /// Vary the header based on how far the player got
    private var headerText: String {
        if isNewHighScore { return "New Record" }
        if round >= 40 { return "Incredible" }
        if round >= 25 { return "Great Run" }
        if round >= 10 { return "Nice Try" }
        return "Game Over"
    }

    /// The near-miss hook
    private var nearMissMessage: String? {
        if !isNewHighScore && highScore > 0 {
            let diff = highScore - score
            if diff <= 500 {
                return "\(diff) points from your best"
            }
        }

        let nextMilestone = ((round / 5) + 1) * 5
        let roundsAway = nextMilestone - round
        if roundsAway <= 2 {
            return "\(roundsAway) round\(roundsAway == 1 ? "" : "s") from Round \(nextMilestone)"
        }

        if closestDistance <= 2, let closest = closestColor, let target = targetColor {
            return "\(closest.name) was close to \(target.name)"
        }

        return nil
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Animated cat mascot
                AnimatedCatView(fps: 8, height: 100)
                    .padding(.bottom, 8)

                // Header
                Text(headerText)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(
                        isNewHighScore
                            ? Color(hex: 0xF59E0B)
                            : Color(hex: 0x3A3A4A)
                    )
                    .padding(.bottom, 12)

                // Score display
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 52, weight: .black, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isNewHighScore
                                    ? [Color(hex: 0xF59E0B), Color(hex: 0xF97316)]
                                    : [Color(hex: 0x3A3A4A), Color(hex: 0x555566)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentTransition(.numericText())

                    Text("POINTS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xBBBBBB))
                        .tracking(3)
                }
                .padding(.bottom, 16)

                // Stats row
                HStack(spacing: 24) {
                    miniStat(label: "ROUND", value: "\(round)")
                    miniStat(label: "BEST", value: "\(highScore)")
                    if hintTokens > 0 {
                        miniStat(label: "HINTS", value: "\(hintTokens)")
                    }
                }
                .padding(.bottom, 12)

                // The near-miss hook — this is the line that makes them hit Play Again
                if let nearMiss = nearMissMessage {
                    Text(nearMiss)
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(Color(hex: 0x8D99AE))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }

                // Target they were trying to reach (unfinished business)
                if let target = targetColor {
                    HStack(spacing: 8) {
                        Text("Needed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: 0xAAAAAA))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [target.highlightColor, target.color],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 22, height: 22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
                            )

                        Text(target.name.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: 0x666666))
                            .tracking(1)
                    }
                    .padding(.bottom, 20)
                }

                // Retry with life
                if lives > 0 {
                    Button(action: onUseLife) {
                        HStack(spacing: 8) {
                            // Mini logo teardrops as life icons
                            HStack(spacing: 3) {
                                ForEach(0..<lives, id: \.self) { _ in
                                    Teardrop()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: 0x555555), Color(hex: 0x333333)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 12, height: 15)
                                }
                            }
                            Text("Retry Round")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(Color(hex: 0x555555))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.8))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color(hex: 0x2A2A2A).opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }

                // Buttons
                HStack(spacing: 12) {
                    // Share button
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x555555))
                            .frame(width: 50, height: 48)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.8))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color(hex: 0x2A2A2A).opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }

                    // Achievements button
                    Button {
                        showAchievements = true
                    } label: {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x555555))
                            .frame(width: 50, height: 48)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.8))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color(hex: 0x2A2A2A).opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }

                    // Play Again button — bold black pill
                    Button(action: onPlayAgain) {
                        Text("Play Again")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                Capsule()
                                    .fill(Color(hex: 0x2A2A2A))
                                    .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
                            )
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.white.opacity(0.9))
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(.white.opacity(0.6), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.12), radius: 30, y: 10)
            )
            .padding(.horizontal, 28)
        }
        .transition(.opacity)
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(image: ShareImageRenderer.render(
                score: score,
                round: round,
                highScore: highScore,
                totalBlends: totalBlends,
                isNewRecord: isNewHighScore
            ))
        }
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: 0x3A3A4A))
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color(hex: 0xBBBBBB))
                .tracking(1)
        }
    }
}
