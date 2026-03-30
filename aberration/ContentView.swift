//
//  PrismGameView.swift
//  aberration
//
//  Prism – Color-Mixing Puzzle Game
//

import SwiftUI

struct PrismGameView: View {
    @State private var game = GameState()

    var body: some View {
        GeometryReader { geo in
            let gridPadding: CGFloat = 32
            let availableWidth = geo.size.width - gridPadding * 2
            let spacing: CGFloat = 4
            let cellSize = max(1, min(64, (availableWidth - CGFloat(GridPosition.gridSize - 1) * spacing) / CGFloat(GridPosition.gridSize)))

            ZStack {
                Color(hex: 0x1D1E2C)
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    // Title
                    Text("PRISM")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: 0xE63946), Color(hex: 0xF4D35E), Color(hex: 0x457B9D)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .tracking(6)

                    // Round / Score / Best
                    HStack(spacing: 24) {
                        statBlock(label: "ROUND", value: "\(game.round)", color: .white)
                        statBlock(label: "SCORE", value: "\(game.score)", color: .white)
                        statBlock(label: "BEST", value: "\(game.highScore)", color: Color(hex: 0xF4D35E))
                    }

                    // Target color
                    if let target = game.targetColor {
                        VStack(spacing: 6) {
                            Text("MAKE THIS COLOR")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: 0x8D99AE))
                                .tracking(2)

                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [target.highlightColor, target.color],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: cellSize * 1.8, height: cellSize * 1.8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: target.color.opacity(0.5), radius: 12)

                            Text(target.name.uppercased())
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(target.color)
                                .tracking(3)
                        }
                        .padding(.vertical, 4)
                        .id(target.wheelIndex)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: target.wheelIndex)
                    }

                    Spacer()

                    // Hint text
                    Text("Tap a tile, then tap another to blend")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: 0x5A5E7A))

                    // Grid
                    GridView(game: game, cellSize: cellSize)

                    Spacer()

                    // New Game button
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            game.newGame()
                        }
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

                // Round complete overlay
                if game.showRoundComplete {
                    roundCompleteOverlay
                }

                // Game over overlay
                if game.isGameOver {
                    GameOverOverlay(score: game.score, round: game.round) {
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

    // MARK: - Subviews

    private func statBlock(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x8D99AE))
                .tracking(2)
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)
        }
    }

    private var roundCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(game.showMilestone ? 0.6 : 0.4)
                .ignoresSafeArea()

            if game.showMilestone {
                milestoneContent
            } else {
                normalRoundContent
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: game.showRoundComplete)
    }

    private var normalRoundContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: 0x2A9D8F))

            Text("ROUND \(game.round - 1)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x8D99AE))
                .tracking(2)

            Text("COMPLETE")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .tracking(4)
        }
    }

    private var milestoneContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: 0xF4D35E))
                .shadow(color: Color(hex: 0xF4D35E).opacity(0.6), radius: 16)

            Text("ROUND \(game.round - 1)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x8D99AE))
                .tracking(2)

            Text("AMAZING!")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: 0xF4D35E), Color(hex: 0xE63946), Color(hex: 0xF4D35E)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(6)

            Text("\(game.score) POINTS")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .tracking(2)
        }
    }
}

#Preview {
    PrismGameView()
}
