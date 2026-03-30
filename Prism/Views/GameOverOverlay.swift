import SwiftUI

struct GameOverOverlay: View {
    let score: Int
    let onPlayAgain: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("GAME OVER")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(4)

                Text("\(score)")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0xF4D35E))

                Text("POINTS")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x8D99AE))
                    .tracking(2)

                Button(action: onPlayAgain) {
                    Text("Play Again")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: 0x457B9D))
                        )
                }
                .padding(.top, 8)
            }
        }
        .transition(.opacity)
    }
}
