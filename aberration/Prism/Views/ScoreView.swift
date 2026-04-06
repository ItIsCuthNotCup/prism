import SwiftUI

struct ScoreView: View {
    let score: Int
    let highScore: Int

    var body: some View {
        HStack(spacing: 32) {
            VStack(spacing: 2) {
                Text("SCORE")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x8D99AE))
                    .tracking(2)
                Text("\(score)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: score)
            }

            VStack(spacing: 2) {
                Text("BEST")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x8D99AE))
                    .tracking(2)
                Text("\(highScore)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0xF4D35E))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: highScore)
            }
        }
    }
}
