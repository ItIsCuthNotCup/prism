import SwiftUI

struct PrismGameView: View {
    @State private var game = GameState()

    var body: some View {
        GeometryReader { geo in
            let gridPadding: CGFloat = 32
            let availableWidth = geo.size.width - gridPadding * 2
            let maxCellSize: CGFloat = 64
            let spacing: CGFloat = 4
            let cellSize = max(1, min(maxCellSize, (availableWidth - CGFloat(GridPosition.gridSize - 1) * spacing) / CGFloat(GridPosition.gridSize)))

            ZStack {
                Color(hex: 0x1D1E2C)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Title
                    Text("PRISM")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: 0xE63946),
                                    Color(hex: 0xF4D35E),
                                    Color(hex: 0x457B9D)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .tracking(6)

                    // Score
                    ScoreView(score: game.score, highScore: game.highScore)

                    Spacer()

                    // Grid
                    GridView(game: game, cellSize: cellSize)

                    Spacer()

                    // Next tile preview
                    NextTilePreview(tileColor: game.nextTile, cellSize: cellSize)

                    // New Game button
                    Button {
                        game.newGame()
                    } label: {
                        Text("New Game")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x8D99AE))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color(hex: 0x3D405B), lineWidth: 1.5)
                            )
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, gridPadding)
                .padding(.top, 8)

                // Game over overlay
                if game.isGameOver {
                    GameOverOverlay(score: game.score) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            game.newGame()
                        }
                    }
                }
            }
        }
        .background(Color(hex: 0x1D1E2C))
        .preferredColorScheme(.dark)
    }
}

#Preview {
    PrismGameView()
}
