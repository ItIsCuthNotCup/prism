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
    @State private var showAchievements = false
    @State private var showNewGameConfirm = false
    @State private var showHowToPlay = false

    var body: some View {
        GeometryReader { geo in
            // Cap total content width for iPad; on iPhone this is just geo.size.width
            let maxContentWidth: CGFloat = min(geo.size.width, 500)
            let contentPadding: CGFloat = 16          // outer margin each side
            let gridInset: CGFloat = 4                // glass container inner padding each side
            let spacing: CGFloat = 5
            // Cell size = (contentWidth - outer padding - grid inset - inter-cell spacing) / columns
            let cellsArea = maxContentWidth - contentPadding * 2 - gridInset * 2
            let cellSize = max(1, (cellsArea - CGFloat(GridPosition.gridSize - 1) * spacing) / CGFloat(GridPosition.gridSize))

            ZStack {
                Color(hex: 0xF5F5F7)
                    .ignoresSafeArea()

                TunnelBackground(depth: game.tunnelDepth, pulseID: game.tunnelDepth, tapPulseID: game.tapPulseID, gameID: game.gameID, frenzy: game.isBackgroundFrenzy, discoveredColorIndices: game.discoveredColorIndices)

                VStack(spacing: 0) {
                    // Settings gear — top right
                    HStack {
                        Spacer()
                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 17, weight: .medium, design: .serif))
                                .foregroundStyle(Color(hex: 0x555555))
                        }
                    }
                    .padding(.bottom, 4)

                  // ── Top container with cat peeking over ──
                  ZStack(alignment: .top) {
                    // 1) Cat behind the card — head peeks above
                    Image("cat_0095")
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 72)

                    // 2) Card drawn on top — covers cat's body
                    VStack(spacing: 8) {
                      // Stats bar — SCORE is the hero
                      HStack(alignment: .center, spacing: 0) {
                          secondaryStat(label: "ROUND", value: "\(game.round)")
                          Spacer()
                          livesDisplay
                          Spacer()
                          heroStat(label: "SCORE", value: "\(game.score)")
                          Spacer()
                          secondaryStat(label: "BEST", value: "\(game.highScore)", accent: true)
                      }
                      .padding(.horizontal, 20)
                      .padding(.vertical, 10)

                    // Target color + progress + blend preview
                    if let target = game.targetColor {
                        VStack(spacing: 8) {
                            // Multi-step progress dots (no label for single target)
                            if game.totalTargetsThisRound > 1 {
                                HStack(spacing: 4) {
                                    ForEach(0..<game.totalTargetsThisRound, id: \.self) { i in
                                        Circle()
                                            .fill(i < game.currentTargetNumber - 1
                                                  ? Color(hex: 0x2A9D8F)
                                                  : (i == game.currentTargetNumber - 1
                                                     ? Color(hex: 0x888888)
                                                     : Color(hex: 0xDDDDDD)))
                                            .frame(width: 6, height: 6)
                                    }
                                }
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

                            VStack(spacing: 3) {
                                Text(target.name.uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(hex: 0x3A3A4A))
                                    .tracking(3)

                                // Blend hint (step count) — separate line, lighter
                                if game.parForCurrentTarget > 0 {
                                    Text("\(game.parForCurrentTarget) \(game.parForCurrentTarget == 1 ? "blend" : "blends")")
                                        .font(.system(size: 11, weight: .medium, design: .serif))
                                        .foregroundStyle(Color(hex: 0xBBBBBB))
                                }
                            }

                            // Blend preview / hint (inside the card)
                            ZStack {
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

                                Text("Tap two colors to blend them")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: 0x999999))
                                    .tracking(1)
                                    .opacity(game.showMergeHint && game.selectedColor == nil ? 1 : 0)
                            }
                            .frame(height: 20)
                            .animation(.easeInOut(duration: 0.15), value: game.selectedPosition)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .id(target.wheelIndex)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: target.wheelIndex)
                    }
                    // Timer removed — zen mode
                    } // end card VStack
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                    .padding(.top, 40)   // push card down so cat face is visible
                    .background(
                        glassCard(cornerRadius: 20)
                            .padding(.top, 40) // glass also starts 40pts down
                    )
                  } // end ZStack (cat + top card)

                    Spacer(minLength: 24)

                  // ── Bottom container: grid + buttons ──
                  VStack(spacing: 0) {
                    // Grid
                    GridView(game: game, cellSize: cellSize)

                    // Bottom buttons (hidden during overlays)
                    ZStack {
                        // Undo — left aligned
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
                                .foregroundStyle(Color(hex: 0x2A2A2A))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.8))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Color(hex: 0x2A2A2A).opacity(0.2), lineWidth: 1)
                                        )
                                        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                                )
                            }
                            .opacity(game.canUndo ? 1 : 0)
                            .allowsHitTesting(game.canUndo)
                            Spacer()
                        }

                        // New Game — always centered, bold black pill
                        Button {
                            if game.round > 1 && !game.isGameOver {
                                showNewGameConfirm = true
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    game.newGame()
                                }
                            }
                        } label: {
                            Text("New Game")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 11)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: 0x2A2A2A))
                                        .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
                                )
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                    .opacity(game.showRoundComplete || game.isGameOver || game.showSubTargetComplete ? 0 : 1)
                    .animation(.easeInOut(duration: 0.2), value: game.canUndo)
                  } // end bottom container
                  .padding(.horizontal, 4)
                  .padding(.vertical, 8)
                  .background(glassCard(cornerRadius: 20))
                }
                .padding(.horizontal, contentPadding)
                .padding(.top, 8)
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                        totalBlends: game.totalBlendsThisGame,
                        lives: game.lives,
                        onUseLife: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                game.useLife()
                            }
                        }
                    ) {
                        // Ad shows after they've seen their score, before new game
                        AdManager.shared.showAdIfScheduled()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            game.newGame()
                        }
                    }
                }

                // Achievement toast (top-right corner)
                if let toast = game.achievementToast {
                    VStack {
                        HStack {
                            Spacer()
                            achievementToastView(toast)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 12)
                        Spacer()
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.achievementToast?.id)
                    .allowsHitTesting(false)
                }
            }
        }
        .background(Color(hex: 0xF5F5F7))
        .preferredColorScheme(.light)
        .onChange(of: game.isGameOver) { _, _ in
            // Game over state change — ad now triggers on Play Again tap, not here
        }
        .sheet(isPresented: $showSettings) {
            settingsView
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
        .fullScreenCover(isPresented: $showStartScreen) {
            startScreenView
        }
        .alert("Start New Game?", isPresented: $showNewGameConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("New Game", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    game.newGame()
                }
            }
        } message: {
            Text("Your current progress will be lost.")
        }
    }

    // MARK: - Glass Card Background

    private func glassCard(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.white.opacity(0.88))
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.thinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.white.opacity(0.9), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
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

    private func heroStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: 0x999999))
                .tracking(2)
            Text(value)
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(Color(hex: 0x2A2A3A))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)
        }
    }

    private func secondaryStat(label: String, value: String, accent: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .serif))
                .foregroundStyle(Color(hex: 0xBBBBBB))
                .tracking(1.5)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(accent ? Color(hex: 0x8D99AE) : Color(hex: 0x6A6A7A))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)
        }
    }

    // MARK: - Lives Display

    private var livesDisplay: some View {
        VStack(spacing: 2) {
            Text("LIVES")
                .font(.system(size: 9, weight: .medium, design: .serif))
                .foregroundStyle(Color(hex: 0xBBBBBB))
                .tracking(1.5)
            HStack(spacing: 4) {
                let maxSlots = max(3, game.lives)
                ForEach(0..<maxSlots, id: \.self) { i in
                    Teardrop()
                        .fill(
                            i < game.lives
                                ? LinearGradient(
                                    colors: [Color(hex: 0xFF5E6C), Color(hex: 0xA080E0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                  )
                                : LinearGradient(
                                    colors: [Color(hex: 0xDDDDDD), Color(hex: 0xCCCCCC)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                  )
                        )
                        .frame(width: 14, height: 18)
                        .opacity(i < game.lives ? 1.0 : 0.3)
                }
            }
            .frame(height: 26) // match number text height for alignment
            .animation(.spring(response: 0.3), value: game.lives)
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
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .foregroundStyle(Color(hex: 0x2A2A3A))

                Text("Next color...")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(Color(hex: 0xAAAAAA))

                if let combo = game.comboMessage {
                    Text(combo)
                        .font(.system(size: 14, weight: .black, design: .serif))
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
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: 0x2A9D8F))
                .shadow(color: Color(hex: 0x2A9D8F).opacity(0.2), radius: 10)

            Text("Round \(game.round)")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: 0x3A3A4A))

            if let combo = game.comboMessage {
                Text(combo)
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundStyle(Color(hex: 0x2A9D8F))
                    .tracking(1)
            }
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 24)
        .background(glassCard(cornerRadius: 24))
    }

    private var milestoneContent: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundStyle(Color(hex: 0xF59E0B))
                .shadow(color: Color(hex: 0xF59E0B).opacity(0.25), radius: 10)

            Text("Round \(game.round)")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: 0x3A3A4A))

            Text("Milestone")
                .font(.system(size: 11, weight: .medium, design: .serif))
                .foregroundStyle(Color(hex: 0xBBBBBB))
                .tracking(2)

            if let combo = game.comboMessage {
                Text(combo)
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundStyle(Color(hex: 0xF59E0B))
                    .tracking(1)
            }
        }
        .padding(.horizontal, 44)
        .padding(.vertical, 24)
        .background(glassCard(cornerRadius: 24))
    }

    // MARK: - Achievement Unlock Row (legacy — kept for reference)

    private var achievementUnlockRow: some View {
        VStack(spacing: 8) {
            Text("Achievement Unlocked!")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: 0xF59E0B))
                .tracking(2)

            HStack(spacing: 10) {
                ForEach(game.recentlyUnlockedAchievements) { achievement in
                    VStack(spacing: 4) {
                        Image(achievement.imageName)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                        Text(achievement.name)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x888888))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Achievement Toast (Top-Right Corner)

    private func achievementToastView(_ achievement: StatsManager.Achievement) -> some View {
        HStack(spacing: 10) {
            if UIImage(named: achievement.imageName) != nil {
                Image(achievement.imageName)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hue: achievement.hue, saturation: 0.4, brightness: 0.9))
                        .frame(width: 44, height: 44)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hue: achievement.hue, saturation: 0.6, brightness: 0.5))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement!")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF59E0B))
                    .tracking(1)

                Text(achievement.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: 0x2A2A3A))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(hex: 0xF59E0B).opacity(0.3), lineWidth: 1)
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

                Button {
                    showSettings = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showAchievements = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color(hex: 0xF59E0B))
                        Text("Achievements")
                            .foregroundStyle(Color(hex: 0x2A2A3A))
                        Spacer()
                        let count = StatsManager.shared.unlockedBadges.count
                        Text("\(count)/\(StatsManager.allAchievements.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: 0xAAAAAA))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xCCCCCC))
                    }
                }

                Section {
                    rulesRow(icon: "drop.fill", color: Color(hex: 0x457B9D),
                             text: "Tap two tiles to blend their colors together")
                    rulesRow(icon: "target", color: Color(hex: 0xE63946),
                             text: "Mix colors to match the target shown above the board")
                    rulesRow(icon: "arrow.triangle.merge", color: Color(hex: 0x2A9D8F),
                             text: "Red, Yellow, and Blue are primary colors — all other colors are made by mixing them")
                    rulesRow(icon: "heart.fill", color: Color(hex: 0xFF5E6C),
                             text: "You start with 3 lives. Spend one to retry a failed round")
                    rulesRow(icon: "heart.circle.fill", color: Color(hex: 0xA080E0),
                             text: "Survive 10 rounds without using a life to earn a bonus life")
                    rulesRow(icon: "arrow.counterclockwise", color: Color(hex: 0xF59E0B),
                             text: "Use undo to take back your last blend (once per round)")
                } header: {
                    Text("How to Play")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.light)
    }

    private func rulesRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: 0x3A3A4A))
        }
        .padding(.vertical, 2)
    }

    // MARK: - Start Screen

    private var startScreenView: some View {
        ZStack {
            Color(hex: 0xF5F5F7)
                .ignoresSafeArea()

            dotGridBackground

            if showHowToPlay {
                // How to Play — clean rules screen
                VStack(spacing: 24) {
                    Spacer()

                    Text("How to Play")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundStyle(Color(hex: 0x2A2A2A))

                    VStack(alignment: .leading, spacing: 16) {
                        howToPlayRow(
                            icon: "hand.tap",
                            text: "Tap two tiles to blend their colors together"
                        )
                        howToPlayRow(
                            icon: "target",
                            text: "Match the target color shown at the top"
                        )
                        howToPlayRow(
                            icon: "paintpalette",
                            text: "Red, Yellow, and Blue are primary — mix them to make any color"
                        )
                        howToPlayRow(
                            icon: "heart",
                            text: "You have 3 lives. Spend one to retry a failed round"
                        )
                        howToPlayRow(
                            icon: "arrow.counterclockwise",
                            text: "Undo takes back your last blend, once per round"
                        )
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    // Play button from rules screen
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showHowToPlay = false
                        }
                        MusicManager.shared.setGameplayVolume()
                        showStartScreen = false
                    } label: {
                        Text("Play")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .tracking(3)
                            .padding(.horizontal, 52)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color(hex: 0x2A2A2A))
                                    .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
                            )
                    }
                    .padding(.bottom, 60)
                }
                .transition(.opacity)
            } else {
                // Main start screen
                VStack(spacing: 32) {
                    Spacer()

                    CatMascotView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)

                    VStack(spacing: 12) {
                        Text("Stillhue")
                            .font(.system(size: 42, weight: .regular, design: .serif))
                            .foregroundStyle(Color(hex: 0x2A2A2A))
                            .tracking(2)

                        Text("A color-blending puzzle")
                            .font(.system(size: 15, weight: .medium, design: .serif))
                            .foregroundStyle(Color(hex: 0x999999))
                    }

                    Spacer()

                    VStack(spacing: 14) {
                        // Play — primary action, bold black pill
                        Button {
                            MusicManager.shared.setGameplayVolume()
                            showStartScreen = false
                        } label: {
                            Text("Play")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .tracking(3)
                                .padding(.horizontal, 52)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: 0x2A2A2A))
                                        .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
                                )
                        }

                        // How to Play — subtle text link
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showHowToPlay = true
                            }
                        } label: {
                            Text("How to Play")
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .foregroundStyle(Color(hex: 0xAAAAAA))
                        }
                    }
                    .padding(.bottom, 60)
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            MusicManager.shared.setMenuVolume()
            MusicManager.shared.startTheme()
        }
    }

    private func howToPlayRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: 0x8D99AE))
                .frame(width: 28)
            Text(text)
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color(hex: 0x4A4A5A))
                .fixedSize(horizontal: false, vertical: true)
        }
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
