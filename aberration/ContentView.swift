//
//  PrismGameView.swift
//  aberration
//
//  Blent – Color-Mixing Puzzle Game
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
                Color(hex: 0xF5F5F7)
                    .ignoresSafeArea()

                TunnelBackground(depth: game.tunnelDepth, pulseID: game.tunnelDepth)

                VStack(spacing: 16) {
                    // Title + Settings — ZStack so BLENT is truly centered
                    ZStack {
                        ChromaHeader()

                        HStack {
                            Spacer()
                            Button {
                                showSettings.toggle()
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(Color(hex: 0xBBBBC8))
                            }
                        }
                    }

                    // Stats bar
                    HStack(spacing: 0) {
                        statBlock(label: "ROUND", value: "\(game.round)")
                        Spacer()
                        statBlock(label: "SCORE", value: "\(game.score)")
                        Spacer()
                        statBlock(label: "BEST", value: "\(game.highScore)", accent: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(glassCard(cornerRadius: 16))

                    // Target color + progress
                    if let target = game.targetColor {
                        VStack(spacing: 8) {
                            // Multi-step progress
                            if game.totalTargetsThisRound > 1 {
                                HStack(spacing: 6) {
                                    Text("TARGET")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(Color(hex: 0xAAAAAA))
                                        .tracking(2)
                                    HStack(spacing: 4) {
                                        ForEach(0..<game.totalTargetsThisRound, id: \.self) { i in
                                            Circle()
                                                .fill(i < game.currentTargetNumber - 1
                                                      ? Color(hex: 0x2A9D8F)
                                                      : (i == game.currentTargetNumber - 1
                                                         ? Color(hex: 0xF59E0B)
                                                         : Color(hex: 0xDDDDDD)))
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                    Text("\(game.currentTargetNumber)/\(game.totalTargetsThisRound)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: 0x888888))
                                }
                            } else {
                                Text("MATCH")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color(hex: 0xAAAAAA))
                                    .tracking(4)
                            }

                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [target.highlightColor, target.color],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
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

                            HStack(spacing: 8) {
                                Text(target.name.uppercased())
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x3A3A4A))
                                    .tracking(3)

                                // Par indicator
                                if game.parForCurrentTarget > 0 {
                                    Text("PAR \(game.parForCurrentTarget)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(Color(hex: 0xBBBBBB))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .strokeBorder(Color(hex: 0xDDDDDD), lineWidth: 0.5)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 2)
                        .id(target.wheelIndex)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: target.wheelIndex)
                    }

                    // Fixed-height hint area — prevents grid from shifting
                    ZStack {
                        // Blend preview — shows selected color
                        if let sel = game.selectedColor {
                            HStack(spacing: 5) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(sel.color)
                                    .frame(width: 12, height: 12)
                                Text("\(sel.shortName) + ?")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color(hex: 0xAAAAAA))
                            }
                        }

                        // First-round hint
                        Text("Tap two colors to blend them")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: 0x999999))
                            .tracking(1)
                            .opacity(game.showMergeHint && game.selectedColor == nil ? 1 : 0)
                    }
                    .frame(height: 20)
                    .animation(.easeInOut(duration: 0.15), value: game.selectedPosition)

                    Spacer(minLength: 0)

                    // Grid
                    GridView(game: game, cellSize: cellSize)

                    // Bottom buttons (hidden during overlays)
                    HStack {
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
                        .opacity(game.canUndo ? 1 : 0)
                        .allowsHitTesting(game.canUndo)

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
                    .opacity(game.showRoundComplete || game.isGameOver || game.showSubTargetComplete || game.showPoisonIntro ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: game.canUndo)
                }
                .padding(.horizontal, gridPadding)
                .padding(.top, 8)

                // Sub-target complete overlay (multi-step)
                if game.showSubTargetComplete {
                    subTargetOverlay
                }

                // Round complete overlay
                if game.showRoundComplete {
                    roundCompleteOverlay
                }

                // Game over overlay
                if game.isGameOver {
                    GameOverOverlay(
                        score: game.score,
                        round: game.round,
                        highScore: game.highScore,
                        bestRound: game.bestRound,
                        emptySpaces: game.emptyPositions().count,
                        targetColor: game.targetColor,
                        closestColor: game.closestColorOnBoard,
                        closestDistance: game.closestColorDistance,
                        totalBlends: game.totalBlendsThisGame
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            game.newGame()
                        }
                    }
                }

                // Poison intro overlay
                if game.showPoisonIntro {
                    poisonIntroOverlay
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

    // MARK: - Glass Card Background

    private func glassCard(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.white.opacity(0.65))
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.white.opacity(0.8), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
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

    // MARK: - Sub-Target Complete Overlay

    private var subTargetOverlay: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: 0x2A9D8F))

                Text("\(game.currentTargetNumber)/\(game.totalTargetsThisRound)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x2A2A3A))

                Text("Next color incoming...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: 0x999999))

                if let combo = game.comboMessage {
                    Text(combo)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: 0xF59E0B))
                        .tracking(2)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 24)
            .background(glassCard(cornerRadius: 24))
        }
        .transition(.opacity)
    }

    // MARK: - Round Complete Overlays

    private var roundCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(game.showMilestone ? 0.3 : 0.2)
                .ignoresSafeArea()

            if game.showMilestone {
                milestoneContent
            } else {
                normalRoundContent
            }

            // (tap to continue is now inside the overlay cards)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                game.dismissRoundComplete()
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

            Text("ROUND \(game.round)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0x888888))
                .tracking(3)

            Text("COMPLETE")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: 0x2A2A3A))
                .tracking(4)

            // Score breakdown
            VStack(spacing: 3) {
                scoreRow(label: "Blends", value: "+\(game.lastRoundBlendPoints)")
                scoreRow(label: "Match", value: "+\(game.lastRoundMatchBonus)")
                if game.lastRoundComboBonus > 0 {
                    scoreRow(label: game.comboMessage?.contains("UNDER") == true ? "Under Par" : "Par",
                             value: "+\(game.lastRoundComboBonus)", accent: true)
                }
            }
            .padding(.top, 4)

            if game.roundCompleteCanDismiss {
                Text("Tap to continue")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: 0xAAAAAA))
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .background(glassCard(cornerRadius: 24))
    }

    private func scoreRow(label: String, value: String, accent: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: 0xAAAAAA))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(accent ? Color(hex: 0xF59E0B) : Color(hex: 0x666666))
        }
        .frame(width: 140)
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

            Text("ROUND \(game.round)")
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

            Text("Milestone Reached")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: 0xBBBBBB))
                .tracking(2)

            Text("\(game.score) POINTS")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: 0x666666))
                .tracking(2)

            if let combo = game.comboMessage {
                Text(combo)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0xF59E0B))
                    .tracking(2)
            }

            if game.roundCompleteCanDismiss {
                Text("Tap to continue")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: 0xAAAAAA))
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .background(glassCard(cornerRadius: 24))
    }

    // MARK: - Poison Intro Overlay

    private var poisonIntroOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0xF59E0B), Color(hex: 0xF97316)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("MIXED TILES")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x2A2A3A))
                    .tracking(4)

                VStack(spacing: 8) {
                    Text("Pre-mixed colors now appear on the board.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: 0x666666))
                        .multilineTextAlignment(.center)

                    Text("They can't help you — and they take up space.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(hex: 0x999999))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 8)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        game.dismissPoisonIntro()
                    }
                } label: {
                    Text("Got it")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0xF59E0B), Color(hex: 0xF97316)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .background(glassCard(cornerRadius: 28))
        }
        .transition(.opacity)
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

                VStack(spacing: 12) {
                    ChromaHeader(fontSize: 52, tracking: 10)

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
