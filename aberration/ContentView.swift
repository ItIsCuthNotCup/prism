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
    @State private var showRewardOffer = false
    @State private var showRewardChest = false
    @State private var pendingReward: GameState.RewardType? = nil
    @State private var activeCelebration: CelebrationType? = nil
    @State private var glowPulse = false
    @State private var aberrationPhase: Double = 0
    @State private var gameOverShake: CGFloat = 0
    /// Countdown: celebration triggers when this hits 0, then resets to a new random 1–6.
    @State private var roundsUntilCelebration: Int = Int.random(in: 1...6)
    /// Cycles through celebration types so they alternate (no long streaks of the same one).
    @State private var nextCelebrationIndex: Int = Int.random(in: 0..<CelebrationType.allCases.count)

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
                    .padding(.bottom, 0)

                  // ── Unified card: cat + stats + target + grid + buttons ──
                  ZStack(alignment: .top) {
                    // Cat behind the card — head peeks above
                    Image("cat_0095")
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 56)

                    VStack(spacing: 0) {
                      // Stats bar — ROUND left, SCORE center, LIVES right
                      HStack(alignment: .center, spacing: 0) {
                          secondaryStat(label: "ROUND", value: "\(game.round)")
                              .frame(maxWidth: .infinity)
                          heroStat(label: "SCORE", value: "\(game.score)")
                              .frame(maxWidth: .infinity)
                          livesDisplay
                              .frame(maxWidth: .infinity)
                      }
                      .padding(.horizontal, 12)
                      .padding(.vertical, 6)

                      // Target color swatch + name
                      if let target = game.targetColor {
                          VStack(spacing: 4) {
                              RoundedRectangle(cornerRadius: 12)
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
                                      .clipShape(RoundedRectangle(cornerRadius: 12))
                                  )
                                  .overlay(
                                      RoundedRectangle(cornerRadius: 12)
                                          .strokeBorder(.white.opacity(0.5), lineWidth: 0.5)
                                  )
                                  .frame(width: cellSize * 1.1, height: cellSize * 1.1)
                                  .shadow(color: target.color.opacity(0.25), radius: 10, y: 3)

                              Text(target.name.uppercased())
                                  .font(.system(size: 13, weight: .bold))
                                  .foregroundStyle(Color(hex: 0x3A3A4A))
                                  .tracking(3)

                              // Selection hint
                              ZStack {
                                  if let sel = game.selectedColor {
                                      HStack(spacing: 5) {
                                          RoundedRectangle(cornerRadius: 3)
                                              .fill(sel.color)
                                              .frame(width: 10, height: 10)
                                          Text("\(sel.name) + ?")
                                              .font(.system(size: 11, weight: .medium))
                                              .foregroundStyle(Color(hex: 0xAAAAAA))
                                      }
                                  }

                                  Text("Tap two colors to mix")
                                      .font(.system(size: 11, weight: .medium))
                                      .foregroundStyle(Color(hex: 0x999999))
                                      .tracking(1)
                                      .opacity(game.showMergeHint && game.selectedColor == nil ? 1 : 0)
                              }
                              .frame(height: 16)
                              .animation(.easeInOut(duration: 0.15), value: game.selectedPosition)
                          }
                          .padding(.bottom, 6)
                          .id(target.wheelIndex)
                          .transition(.scale.combined(with: .opacity))
                          .animation(.spring(response: 0.4), value: target.wheelIndex)
                      }

                      // Thin separator
                      Rectangle()
                          .fill(Color(hex: 0xDDDDDD).opacity(0.5))
                          .frame(height: 0.5)
                          .padding(.horizontal, 12)

                      // Grid
                      GridView(game: game, cellSize: cellSize)
                          .padding(.top, 4)

                      // Bottom buttons — all flat text, consistent style
                      HStack(spacing: 0) {
                          // Undo — left
                          Button {
                              withAnimation(.easeInOut(duration: 0.2)) {
                                  game.undoLastBlend()
                              }
                          } label: {
                              HStack(spacing: 4) {
                                  Image(systemName: "arrow.uturn.backward")
                                      .font(.system(size: 12, weight: .semibold))
                                  Text("Undo")
                                      .font(.system(size: 13, weight: .semibold))
                              }
                              .foregroundStyle(Color(hex: 0x3A3A4A))
                              .frame(maxWidth: .infinity)
                              .padding(.vertical, 10)
                          }
                          .opacity(game.canUndo ? 1 : 0.2)
                          .allowsHitTesting(game.canUndo)

                          // New Game — center
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
                                  .font(.system(size: 13, weight: .semibold))
                                  .foregroundStyle(Color(hex: 0x3A3A4A))
                                  .frame(maxWidth: .infinity)
                                  .padding(.vertical, 10)
                          }

                          // Hint — right
                          Button {
                              withAnimation(.easeInOut(duration: 0.2)) {
                                  _ = game.useHintToken()
                              }
                          } label: {
                              HStack(spacing: 4) {
                                  Image(systemName: "lightbulb.fill")
                                      .font(.system(size: 12, weight: .semibold))
                                  Text("Hint")
                                      .font(.system(size: 13, weight: .semibold))
                                  if game.hintTokens > 0 {
                                      Text("\(game.hintTokens)")
                                          .font(.system(size: 11, weight: .bold))
                                          .foregroundStyle(.white)
                                          .frame(width: 18, height: 18)
                                          .background(Circle().fill(Color(hex: 0x5A9BC7)))
                                  }
                              }
                              .foregroundStyle(game.hintTokens > 0 ? Color(hex: 0x3A3A4A) : Color(hex: 0xBBBBBB))
                              .frame(maxWidth: .infinity)
                              .padding(.vertical, 10)
                          }
                          .opacity(game.hintTokens > 0 && !game.hintActive ? 1 : 0.2)
                          .allowsHitTesting(game.hintTokens > 0 && !game.hintActive)
                      }
                      .padding(.horizontal, 8)
                      .padding(.bottom, 4)
                      .opacity(game.isGameOver ? 0 : 1)
                      .animation(.easeInOut(duration: 0.2), value: game.canUndo)

                    } // end card VStack
                    .padding(.horizontal, 4)
                    .padding(.top, 40)   // push card down so cat face is visible
                    .padding(.bottom, 4)
                    .background(
                        glassCard(cornerRadius: 20)
                            .padding(.top, 40)
                    )
                  } // end ZStack (unified card)
                  .overlay(
                    ChromaticAberrationBorder(
                        cornerRadius: 20,
                        phase: aberrationPhase,
                        intensity: game.activeMultiplierSource == .none ? 0 : (glowPulse ? 1.0 : 0.3)
                    )
                    .padding(.top, 40) // match the card offset
                    .allowsHitTesting(false)
                  )
                  .onChange(of: game.activeMultiplierSource) { _, newSource in
                      if newSource != .none {
                          withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                              glowPulse = true
                          }
                          withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                              aberrationPhase = 1.0
                          }
                      } else {
                          withAnimation(.easeOut(duration: 0.3)) {
                              glowPulse = false
                              aberrationPhase = 0
                          }
                      }
                  }
                }
                .padding(.horizontal, contentPadding)
                .padding(.top, 4)
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: gameOverShake)

                // Score feedback: bonus label → merges into total → fades
                FloatingPointsView(
                    amount: game.floatingPointsAmount,
                    multiplier: game.floatingPointsMultiplier,
                    trigger: game.floatingPointsTrigger,
                    color: game.floatingPointsColor,
                    bonus: game.lastEarnedBonus,
                    bonusTrigger: game.bonusTrigger
                )

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
                        hintTokens: game.hintTokens,
                        onUseLife: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                game.useLife()
                            }
                        }
                    ) {
                        // Play Again tapped — check if we should offer a reward
                        if AdManager.shared.shouldOfferReward {
                            showRewardOffer = true
                        } else {
                            // Normal flow: interstitial check + new game
                            AdManager.shared.showInterstitialIfScheduled()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                game.newGame()
                            }
                        }
                    }
                }

                // Reward offer overlay (opt-in to ad)
                if showRewardOffer {
                    RewardOfferView(
                        onWatchAd: {
                            showRewardOffer = false
                            AdManager.shared.showRewardedAd { success in
                                if success {
                                    // Grant reward and show chest
                                    let reward = game.grantReward()
                                    pendingReward = reward
                                    showRewardChest = true
                                } else {
                                    // Ad failed — just start new game
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        game.newGame()
                                    }
                                }
                            }
                        },
                        onDecline: {
                            showRewardOffer = false
                            AdManager.shared.declineReward()
                            // Normal flow: interstitial check + new game
                            AdManager.shared.showInterstitialIfScheduled()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                game.newGame()
                            }
                        }
                    )
                    .transition(.opacity)
                }

                // Reward chest animation (after watching ad)
                if showRewardChest, let reward = pendingReward {
                    RewardChestView(reward: reward) {
                        showRewardChest = false
                        pendingReward = nil
                        withAnimation(.easeInOut(duration: 0.3)) {
                            game.newGame()
                        }
                    }
                    .transition(.opacity)
                }

                // Random celebration — pinned to bottom of screen
                if let celebration = activeCelebration {
                    celebrationView(for: celebration)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .transition(.identity)
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
        .onChange(of: game.completedRoundCount) { _, _ in
            // Countdown-based celebration: triggers after 1–6 rounds, then resets
            roundsUntilCelebration -= 1
            if roundsUntilCelebration <= 0 {
                let types = CelebrationType.allCases
                activeCelebration = types[nextCelebrationIndex % types.count]
                nextCelebrationIndex = (nextCelebrationIndex + 1) % types.count
                roundsUntilCelebration = Int.random(in: 1...6)
            }
        }
        .onChange(of: game.isGameOver) { _, isOver in
            if isOver {
                // Screen shake feedback on game over
                withAnimation(.spring(response: 0.08, dampingFraction: 0.3)) {
                    gameOverShake = 8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.08, dampingFraction: 0.3)) {
                        gameOverShake = -6
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                        gameOverShake = 0
                    }
                }
            }
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

    // MARK: - Multiplier Glow (chromatic aberration border)

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
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: 0x888888))
                .tracking(2)
            Text(value)
                .font(.system(size: 26, weight: .black, design: .serif))
                .foregroundStyle(Color(hex: 0x2A2A3A))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)
        }
    }

    private func secondaryStat(label: String, value: String, accent: Bool = false) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: 0x888888))
                .tracking(1.5)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(accent ? Color(hex: 0x8D99AE) : Color(hex: 0x5A5A6A))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)
        }
    }

    // MARK: - Lives Display

    private var livesDisplay: some View {
        VStack(spacing: 1) {
            Text("LIVES")
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: 0x888888))
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

    // MARK: - Round Complete (non-blocking FloatingPointsView)

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
                .tint(Color(hex: 0xE8876B))

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
                    rulesRow(icon: "drop.fill", color: Color(hex: 0xD4724A),
                             text: "Tap two tiles to mix their colors")
                    rulesRow(icon: "target", color: Color(hex: 0xE63946),
                             text: "Mix colors to match the target above the board")
                    rulesRow(icon: "arrow.triangle.merge", color: Color(hex: 0xE8876B),
                             text: "Red, Yellow, and Blue are primary — mix them to make any color")
                    rulesRow(icon: "heart.fill", color: Color(hex: 0xFF5E6C),
                             text: "3 lives. Spend one to retry a round")
                    rulesRow(icon: "heart.circle.fill", color: Color(hex: 0xA080E0),
                             text: "Survive 10 rounds without losing a life to earn a bonus life")
                    rulesRow(icon: "arrow.counterclockwise", color: Color(hex: 0xF59E0B),
                             text: "Undo takes back your last move, once per round")
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
                            text: "Tap two tiles to mix their colors"
                        )
                        howToPlayRow(
                            icon: "target",
                            text: "Match the target color at the top"
                        )
                        howToPlayRow(
                            icon: "paintpalette",
                            text: "Red, Yellow, and Blue are primary — mix them to make any color"
                        )
                        howToPlayRow(
                            icon: "heart",
                            text: "You have 3 lives. Spend one to retry a round"
                        )
                        howToPlayRow(
                            icon: "arrow.counterclockwise",
                            text: "Undo takes back your last move, once per round"
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

                        Text("A color-mixing puzzle")
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

    // MARK: - Celebrations

    @ViewBuilder
    private func celebrationView(for type: CelebrationType) -> some View {
        switch type {
        case .clappingCat:
            CelebrationCatView {
                activeCelebration = nil
            }
        case .mouseChase:
            ChaseCatView {
                activeCelebration = nil
            }
        case .binocularsCat:
            BinocularsCatView {
                activeCelebration = nil
            }
        case .stretchCat:
            StretchCatView {
                activeCelebration = nil
            }
        case .rollCat:
            RollCatView {
                activeCelebration = nil
            }
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
