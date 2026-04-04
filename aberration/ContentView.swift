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
    @State private var showDailyPuzzle = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage? = nil
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
    /// Work item for auto-dismissing the bottom toast
    @State private var toastDismissWork: DispatchWorkItem? = nil

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
                    // Settings gear — top left
                    HStack {
                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color(hex: 0x555555))
                        }
                        Spacer()
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
                      // Stats bar — ROUND left, SCORE center, LIVES+HINT right
                      HStack(alignment: .center, spacing: 0) {
                          secondaryStat(label: "ROUND", value: "\(game.round)")
                              .frame(maxWidth: .infinity)
                          heroStat(label: "SCORE", value: "\(game.score)")
                              .frame(maxWidth: .infinity)
                          livesAndHintDisplay
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

                              // Selection hint (formula area)
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
                                  } else if game.showMergeHint && game.tutorialCoachText == nil {
                                      Text("Tap two colors to mix")
                                          .font(.system(size: 11, weight: .medium))
                                          .foregroundStyle(Color(hex: 0x999999))
                                          .tracking(1)
                                  }
                              }
                              .frame(height: 16)
                              .animation(.easeInOut(duration: 0.2), value: game.selectedPosition)
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

                      // Grid with optional tutorial tooltip
                      ZStack {
                          GridView(game: game, cellSize: cellSize)

                          // Tutorial tooltip on round 1 — clean, centered above hinted tiles
                          if game.showTutorialArrows {
                              tutorialTooltipOverlay(cellSize: cellSize, spacing: spacing)
                                  .allowsHitTesting(false)
                                  .transition(.opacity)
                          }
                      }
                      .padding(.top, 4)
                      .animation(.easeInOut(duration: 0.3), value: game.showTutorialArrows)

                      // (Bottom buttons removed — moved to bottom nav bar)

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

                // ── Top toast: notifications, coaching, hints ──
                // Slides down from top of screen
                VStack {
                    if let toastText = game.toastText {
                        topToastView(text: toastText, accentColor: game.toastAccentColor)
                            .padding(.horizontal, contentPadding + 4)
                            .padding(.top, 4)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                )
                            )
                    }
                    Spacer()
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: game.toastText)
                .allowsHitTesting(false)

                // ── Bottom navigation bar ──
                VStack {
                    Spacer()
                    bottomNavBar
                }
                .ignoresSafeArea(.keyboard)

                // Random celebration — pinned to bottom of screen (above toast)
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
                // Dismiss any active toast
                withAnimation(.easeOut(duration: 0.2)) { game.toastText = nil }
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
        .onChange(of: game.toastText) { _, newText in
            // Auto-dismiss toast after 3 seconds
            toastDismissWork?.cancel()
            if newText != nil {
                let work = DispatchWorkItem {
                    withAnimation(.easeOut(duration: 0.3)) {
                        game.toastText = nil
                    }
                }
                toastDismissWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
            }
        }
        .sheet(isPresented: $showSettings) {
            settingsView
        }
        .sheet(isPresented: $showAchievements) {
            AwardsContainerView()
        }
        .fullScreenCover(isPresented: $showStartScreen) {
            startScreenView
        }
        .fullScreenCover(isPresented: $showDailyPuzzle) {
            DailyPuzzleView()
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheet(image: img)
            }
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
            ScrollView {
                VStack(spacing: 16) {
                    // ── Preferences ──
                    VStack(spacing: 0) {
                        settingsSectionHeader("Preferences")

                        VStack(spacing: 0) {
                            // Color Assistance
                            HStack(spacing: 12) {
                                Image(systemName: "eye")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color(hex: 0xA080E0))
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Color Assistance")
                                        .font(.system(size: 14, weight: .medium, design: .serif))
                                        .foregroundStyle(Color(hex: 0x3A3A4A))
                                    Text("Show color names on tiles")
                                        .font(.system(size: 11, weight: .regular, design: .serif))
                                        .foregroundStyle(Color(hex: 0x999999))
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { game.showColorLabels },
                                    set: { game.showColorLabels = $0 }
                                ))
                                .tint(Color(hex: 0xA080E0))
                                .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            settingsDivider()

                            // Sound Effects
                            HStack(spacing: 12) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: 0xE8876B))
                                    .frame(width: 24)
                                Text("Sound Effects")
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                    .foregroundStyle(Color(hex: 0x3A3A4A))
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { SoundManager.shared.sfxEnabled },
                                    set: { SoundManager.shared.sfxEnabled = $0 }
                                ))
                                .tint(Color(hex: 0xE8876B))
                                .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            settingsDivider()

                            // Music
                            HStack(spacing: 12) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color(hex: 0xD4724A))
                                    .frame(width: 24)
                                Text("Music")
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                    .foregroundStyle(Color(hex: 0x3A3A4A))
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { SoundManager.shared.musicEnabled },
                                    set: { SoundManager.shared.musicEnabled = $0 }
                                ))
                                .tint(Color(hex: 0xD4724A))
                                .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            settingsDivider()

                            // Haptics
                            HStack(spacing: 12) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: 0xFF5E6C))
                                    .frame(width: 24)
                                Text("Haptics")
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                    .foregroundStyle(Color(hex: 0x3A3A4A))
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { HapticManager.isEnabled },
                                    set: { HapticManager.isEnabled = $0 }
                                ))
                                .tint(Color(hex: 0xFF5E6C))
                                .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(settingsCardBackground)
                    }

                    // ── How to Play ──
                    VStack(spacing: 0) {
                        settingsSectionHeader("How to Play")

                        VStack(spacing: 0) {
                            settingsRulesRow(icon: "drop.fill", color: Color(hex: 0xD4724A),
                                             text: "Tap two tiles to mix their colors")
                            settingsDivider()
                            settingsRulesRow(icon: "target", color: Color(hex: 0xE63946),
                                             text: "Mix colors to match the target above the board")
                            settingsDivider()
                            settingsRulesRow(icon: "arrow.triangle.merge", color: Color(hex: 0xE8876B),
                                             text: "Red, Yellow, and Blue are primary — mix them to make any color")
                            settingsDivider()
                            settingsRulesRow(icon: "heart.fill", color: Color(hex: 0xFF5E6C),
                                             text: "3 lives. Spend one to retry a round")
                            settingsDivider()
                            settingsRulesRow(icon: "heart.circle.fill", color: Color(hex: 0xA080E0),
                                             text: "Survive 10 rounds without losing a life to earn a bonus life")
                            settingsDivider()
                            settingsRulesRow(icon: "arrow.counterclockwise", color: Color(hex: 0xF59E0B),
                                             text: "Undo takes back your last move, once per round")
                        }
                        .background(settingsCardBackground)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(hex: 0xF5F5F7))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showSettings = false }
                        .font(.system(size: 15, weight: .medium, design: .serif))
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.light)
    }

    private func settingsRulesRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 24, alignment: .center)
            Text(text)
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color(hex: 0x3A3A4A))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func settingsSectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold, design: .serif))
            .foregroundStyle(Color(hex: 0xAAAAAA))
            .tracking(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .padding(.bottom, 6)
    }

    private var settingsCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.88))
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.9), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private func settingsDivider() -> some View {
        Rectangle()
            .fill(Color(hex: 0xDDDDDD).opacity(0.5))
            .frame(height: 0.5)
            .padding(.leading, 52)
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
                // Main start screen — NYT-style layout
                VStack(spacing: 0) {
                    Spacer()

                    // Branding
                    CatMascotView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .padding(.bottom, 8)

                    Text("Stillhue")
                        .font(.system(size: 42, weight: .regular, design: .serif))
                        .foregroundStyle(Color(hex: 0x2A2A2A))
                        .tracking(2)
                        .padding(.bottom, 2)

                    Text("A color-mixing puzzle")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(Color(hex: 0x999999))
                        .padding(.bottom, 28)

                    // Game mode cards
                    VStack(spacing: 12) {
                        // Classic Mode — primary card
                        Button {
                            MusicManager.shared.setGameplayVolume()
                            showStartScreen = false
                        } label: {
                            HStack(spacing: 14) {
                                // Color circle icon
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: 0xD4724A), Color(hex: 0xE8876B)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 42, height: 42)
                                    Image(systemName: "paintpalette.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Classic")
                                        .font(.system(size: 17, weight: .semibold, design: .serif))
                                        .foregroundStyle(Color(hex: 0x2A2A2A))
                                    Text("Mix colors, beat rounds, chase your high score")
                                        .font(.system(size: 12, weight: .regular, design: .serif))
                                        .foregroundStyle(Color(hex: 0x888888))
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: 0xCCCCCC))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.88))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.thinMaterial)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(.white.opacity(0.9), lineWidth: 0.5)
                                    )
                                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                            )
                        }

                        // Hue of the Day — daily card
                        Button {
                            showDailyPuzzle = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: 0x5A9BC7), Color(hex: 0x8D99AE)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 42, height: 42)
                                    Image(systemName: "calendar")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text("Hue of the Day")
                                            .font(.system(size: 17, weight: .semibold, design: .serif))
                                            .foregroundStyle(Color(hex: 0x2A2A2A))
                                        // Daily indicator dot
                                        if !DailyPuzzleState().hasPlayedToday {
                                            Circle()
                                                .fill(Color(hex: 0xFF5E6C))
                                                .frame(width: 7, height: 7)
                                        }
                                    }
                                    Text("Mix 3 tiles to match today's color")
                                        .font(.system(size: 12, weight: .regular, design: .serif))
                                        .foregroundStyle(Color(hex: 0x888888))
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: 0xCCCCCC))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.88))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.thinMaterial)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(.white.opacity(0.9), lineWidth: 0.5)
                                    )
                                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // How to Play — bottom link
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showHowToPlay = true
                        }
                    } label: {
                        Text("How to Play")
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .foregroundStyle(Color(hex: 0xAAAAAA))
                    }
                    .padding(.bottom, 40)
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            MusicManager.shared.setMenuVolume()
            MusicManager.shared.startTheme()
        }
        .fullScreenCover(isPresented: $showDailyPuzzle) {
            DailyPuzzleView()
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

    // MARK: - Tutorial Tooltip Overlay

    /// A single clean tooltip centered above the hinted tiles on round 1.
    /// Uses a pill shape with a subtle downward arrow, colored in the target color.
    private func tutorialTooltipOverlay(cellSize: CGFloat, spacing: CGFloat) -> some View {
        let gridInset: CGFloat = 4
        let gridSize = GridPosition.gridSize
        let totalWidth = CGFloat(gridSize) * cellSize + CGFloat(gridSize - 1) * spacing + gridInset * 2
        let totalHeight = totalWidth  // square grid

        // Find center point between the two hinted tiles
        let positions = Array(game.hintPositions)
        let centerX: CGFloat
        let topY: CGFloat
        if positions.count >= 2 {
            let xs = positions.map { gridInset + CGFloat($0.col) * (cellSize + spacing) + cellSize / 2 }
            let ys = positions.map { gridInset + CGFloat($0.row) * (cellSize + spacing) + cellSize / 2 }
            centerX = xs.reduce(0, +) / CGFloat(xs.count)
            topY = ys.min()! - cellSize / 2
        } else if let pos = positions.first {
            centerX = gridInset + CGFloat(pos.col) * (cellSize + spacing) + cellSize / 2
            topY = gridInset + CGFloat(pos.row) * (cellSize + spacing)
        } else {
            centerX = totalWidth / 2
            topY = totalHeight / 2
        }

        return ZStack {
            VStack(spacing: 0) {
                Text("Tap both to mix")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(hex: 0x2A2A2A).opacity(0.75))
                            .overlay(
                                Capsule()
                                    .fill(.ultraThinMaterial.opacity(0.3))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
                    )

                // Small triangle pointing down
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: 0x2A2A2A).opacity(0.75))
                    .offset(y: -2)
            }
            .position(x: centerX, y: topY - 16)
            .modifier(GentleBounce())
        }
        .frame(width: totalWidth, height: totalHeight)
    }

    // MARK: - Top Toast

    /// Toast that slides down from top of screen.
    /// Glass card style matching the main card, with subtle accent color.
    private func topToastView(text: String, accentColor: Color?) -> some View {
        return HStack(spacing: 0) {
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(Color(hex: 0x3A3A4A))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }

    // MARK: - Lives + Hint Display (combined)

    /// Lives teardrops with a hint button tucked underneath.
    private var livesAndHintDisplay: some View {
        VStack(spacing: 3) {
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
            .frame(height: 22)
            .animation(.spring(response: 0.3), value: game.lives)

            // Hint button — compact, right next to lives
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    _ = game.useHintToken()
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10, weight: .semibold))
                    if game.hintTokens > 0 {
                        Text("\(game.hintTokens)")
                            .font(.system(size: 10, weight: .bold))
                    }
                }
                .foregroundStyle(game.hintTokens > 0 ? Color(hex: 0x5A9BC7) : Color(hex: 0xCCCCCC))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(game.hintTokens > 0 ? Color(hex: 0x5A9BC7).opacity(0.1) : Color(hex: 0xEEEEEE))
                )
            }
            .opacity(game.hintTokens > 0 && !game.hintActive ? 1 : 0.3)
            .allowsHitTesting(game.hintTokens > 0 && !game.hintActive)
        }
    }

    // MARK: - Bottom Navigation Bar

    /// 5-icon tab bar: Hue of Day, New Game, Home, Achievements, Share
    private var bottomNavBar: some View {
        HStack(spacing: 0) {
            // Hue of the Day
            navBarButton(icon: "calendar", label: "Daily") {
                showDailyPuzzle = true
            }

            // New Game
            navBarButton(icon: "arrow.counterclockwise", label: "New") {
                if game.round > 1 && !game.isGameOver {
                    showNewGameConfirm = true
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        game.newGame()
                    }
                }
            }

            // Home (center, larger)
            Button {
                showStartScreen = true
                MusicManager.shared.setMenuVolume()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color(hex: 0x2A2A2A))
                    Text("Home")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color(hex: 0x888888))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }

            // Achievements
            navBarButton(icon: "trophy", label: "Awards") {
                showAchievements = true
            }

            // Share
            navBarButton(icon: "square.and.arrow.up", label: "Share") {
                let img = ShareImageRenderer.render(
                    score: game.score,
                    round: game.round,
                    highScore: game.highScore,
                    totalBlends: game.totalBlendsThisGame,
                    isNewRecord: game.score >= game.highScore && game.score > 0
                )
                shareImage = img
                showShareSheet = true
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    VStack {
                        Rectangle()
                            .fill(Color(hex: 0xDDDDDD).opacity(0.5))
                            .frame(height: 0.5)
                        Spacer()
                    }
                )
                .ignoresSafeArea(.all, edges: .bottom)
        )
    }

    private func navBarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: 0x4A4A4A))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(hex: 0x888888))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
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

// MARK: - Gentle Bounce Animation

/// Repeating small vertical bounce for tutorial arrows.
private struct GentleBounce: ViewModifier {
    @State private var bouncing = false

    func body(content: Content) -> some View {
        content
            .offset(y: bouncing ? -4 : 4)
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true),
                value: bouncing
            )
            .onAppear { bouncing = true }
    }
}

#Preview {
    PrismGameView()
}
