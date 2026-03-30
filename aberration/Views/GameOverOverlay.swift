import SwiftUI

struct GameOverOverlay: View {
    let score: Int
    let round: Int
    let emptySpaces: Int
    let onPlayAgain: () -> Void

    private var message: String {
        if emptySpaces <= 0 {
            return "Board full — no room for new tiles"
        } else {
            return "No blends left to reach the target"
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("GAME OVER")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x2A2A3A))
                    .tracking(4)

                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: 0x999999))

                VStack(spacing: 6) {
                    Text("Round \(round)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x888888))

                    Text("\(score)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: 0xF59E0B), Color(hex: 0xF97316)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("POINTS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xAAAAAA))
                        .tracking(3)
                }

                Button(action: onPlayAgain) {
                    Text("Play Again")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0x457B9D), Color(hex: 0x2A9D8F)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(hex: 0x457B9D).opacity(0.3), radius: 12, y: 4)
                        )
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 32)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.white.opacity(0.85))
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(.white.opacity(0.6), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.1), radius: 30, y: 10)
            )
        }
        .transition(.opacity)
    }
}
