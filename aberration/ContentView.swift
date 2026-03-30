//
//  PrismGameView.swift
//  aberration
//
//  Prism – Color-Mixing Puzzle Game
//

import SwiftUI

struct PrismGameView: View {
    @State private var game = GameState()
    @State private var showSettings = false
    @State private var showStartScreen = true

    var body: some View {
        GeometryReader { geo in
            let gridPadding: CGFloat = 24
            let availableWidth = geo.size.width - gridPadding * 2
            let spacing: CGFloat = 5
            let cellSize = max(1, min(64, (availableWidth - CGFloat(GridPosition.gridSize - 1) * spacing) / CGFloat(GridPosition.gridSize)))

            ZStack {
                // White background with dot grid
                Color(hex: 0xF5F5F7)
                    .ignoresSafeArea()

                dotGridBackground

                VStack(spacing: 16) {
                    // Title + Settings
                    HStack {
                        Spacer()
                        Text("PRISM")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: 0xE63946),
                                        Color(hex: 0xF4A261),
                                        Color(hex: 0x2A9D8F),
                                        Color(hex: 0x457B9D)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .tracking(8)
                        Spacer()
                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color(hex: 0xBBBBC8))
                        }
                    }

                    // Stats bar — glass card
                    HStack(spacing: 0) {
                        statBlock(label: "ROUND", value: "\(game.round)")
                        Spacer()
                        statBlock(label: "SCORE", value: "\(game.score)")
                        Spacer()
                        statBlock(label: "BEST", value: "\(game.highScore)", accent: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.65))
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(.white.opacity(0.8), lineWidth: 0.5)
                        }
                        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
                    )

                    // Target color
                    if let target = game.targetColor {
                        VStack(spacing: 8) {
                            Text("MATCH")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: 0xAAAAAA))
                                .tracking(4)

                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [target.highlightColor, target.color],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    // Glass highlight
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .white.opacity(0.05), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .center
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
                                )
                                .frame(width: cellSize * 1.6, height: cellSize * 1.6)
                                .shadow(color: target.color.opacity(0.3), radius: 16, y: 4)

                            Text(target.name.uppercased())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(hex: 0x3A3A4A))
                                .tracking(3)
                        }
                        .padding(.vertical, 2)
                        .id(target.wheelIndex)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: target.wheelIndex)
                    }

                    // First-round hint
                    if game.showMergeHint {
                        Text("Merge the colors")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: 0x999999))
                            .tracking(1)
                            .transition(.opacity)
                    }

                    Spacer()

                    // Grid
                    GridView(game: game, cellSize: cellSize)

                    // Bottom buttons
                    HStack {
                        if game.canUndo {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    game.undoLastBlend()
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text("Undo")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x555555))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.8))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(.white, lineWidth: 0.5)
                                        )
                                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                                )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                game.newGame()
                            }
                        } label: {
                            Text("New Game")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: 0xAAAAAA))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .strokeBorder(Color(hex: 0xDDDDDD), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                    .animation(.easeInOut(duration: 0.2), value: game.canUndo)
                }
                .padding(.horizontal, gridPadding)
                .padding(.top, 8)

                // Round complete overlay
                if game.showRoundComplete {
                    roundCompleteOverlay
                }

                // Game over overlay
                if game.isGameOver {
                    GameOverOverlay(score: game.score, round: game.round, emptySpaces: game.emptyPositions().count) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            game.newGame()
                        }
                    }
                }
            }
        }
        .background(Color(hex: 0xF5F5F7))
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSettings) {
            settingsView
        }
        .fullScreenCover(isPresented: $showStartScreen) {
            startScreenView
        }
    }

    // MARK: - Dot Grid Background

    private var dotGridBackground: some View {
        Canvas { context, size in
            let dotSpacing: CGFloat = 20
            let dotRadius: CGFloat = 0.7
            for x in stride(from: CGFloat(0), to: size.width, by: dotSpacing) {
                for y in stride(from: CGFloat(0), to: size.height, by: dotSpacing) {
                    let rect = CGRect(
                        x: x - dotRadius,
                        y: y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.08)))
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Subviews

    private func statBlock(label: String, value: String, accent: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(hex: 0xAAAAAA))
                .tracking(2)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(accent ? Color(hex: 0xF59E0B) : Color(hex: 0x2A2A3A))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)
        }
    }

    private var roundCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(game.showMilestone ? 0.3 : 0.2)
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
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color(hex: 0x2A9D8F))
                .shadow(color: Color(hex: 0x2A9D8F).opacity(0.3), radius: 12)

            Text("ROUND \(game.round - 1)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0x888888))
                .tracking(3)

            Text("COMPLETE")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: 0x2A2A3A))
                .tracking(4)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.85))
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(.white.opacity(0.6), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.1), radius: 30, y: 10)
        )
    }

    private var milestoneContent: some View {
        VStack(spacing: 14) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: 0xF59E0B), Color(hex: 0xF97316)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: 0xF59E0B).opacity(0.4), radius: 16)

            Text("ROUND \(game.round - 1)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0x888888))
                .tracking(3)

            Text("AMAZING!")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: 0xF59E0B), Color(hex: 0xE63946), Color(hex: 0xF59E0B)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(6)

            Text("\(game.score) POINTS")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: 0x666666))
                .tracking(2)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.85))
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(.white.opacity(0.6), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.1), radius: 30, y: 10)
        )
    }

    // MARK: - Settings Sheet

    private var settingsView: some View {
        NavigationStack {
            List {
                Toggle("Show color labels on tiles", isOn: Binding(
                    get: { game.showColorLabels },
                    set: { game.showColorLabels = $0 }
                ))
                .tint(Color(hex: 0x2A9D8F))
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.light)
    }

    // MARK: - Start Screen

    private var startScreenView: some View {
        ZStack {
            Color(hex: 0xF5F5F7)
                .ignoresSafeArea()

            dotGridBackground

            VStack(spacing: 40) {
                Spacer()

                // Logo
                VStack(spacing: 12) {
                    Text("PRISM")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: 0xE63946),
                                    Color(hex: 0xF4A261),
                                    Color(hex: 0x2A9D8F),
                                    Color(hex: 0x457B9D)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .tracking(10)

                    // Mini demo: three glass circles
                    HStack(spacing: 14) {
                        glassCircle(color: Color(hex: 0xDF1F1F))
                        Text("+")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(hex: 0xCCCCCC))
                        glassCircle(color: Color(hex: 0x1F4FDF))
                        Text("=")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color(hex: 0xCCCCCC))
                        glassCircle(color: Color(hex: 0xAF1FDF))
                    }
                }

                VStack(spacing: 8) {
                    Text("Blend colors to match the target.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: 0x888888))

                    Text("Keep the board clear — or it's game over.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(hex: 0xBBBBBB))
                }

                Spacer()

                Button {
                    showStartScreen = false
                } label: {
                    Text("Play")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .tracking(4)
                        .padding(.horizontal, 52)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0x457B9D), Color(hex: 0x2A9D8F)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(hex: 0x457B9D).opacity(0.3), radius: 16, y: 6)
                        )
                }
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.light)
    }

    private func glassCircle(color: Color) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.9), color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Glass highlight
                LinearGradient(
                    colors: [.white.opacity(0.5), .white.opacity(0.05), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
                .clipShape(Circle())
            )
            .overlay(
                Circle()
                    .strokeBorder(.white.opacity(0.4), lineWidth: 0.5)
            )
            .frame(width: 38, height: 38)
            .shadow(color: color.opacity(0.3), radius: 8, y: 2)
    }
}

#Preview {
    PrismGameView()
}
