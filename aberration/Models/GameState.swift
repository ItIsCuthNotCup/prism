import SwiftUI

@Observable
class GameState {
    let gridSize = GridPosition.gridSize

    var grid: [[PrismColor?]]
    var targetColor: PrismColor?
    var round: Int = 0
    var score: Int = 0
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: "blent_high_score") }
        set { UserDefaults.standard.set(newValue, forKey: "blent_high_score") }
    }
    var isGameOver: Bool = false

    // MARK: - Timer (disabled — zen mode)
    var timeRemaining: Double = 0
    var timerLimit: Double = 0
    var timerActive: Bool = false
    var hasTimer: Bool { false }
    var selectedPosition: GridPosition? = nil
    var isProcessing: Bool = false
    var showRoundComplete: Bool = false
    var roundCompleteCanDismiss: Bool = false
    var matchedPosition: GridPosition? = nil
    var lastBlendPosition: GridPosition? = nil
    var blendingPositions: (GridPosition, GridPosition)? = nil
    /// Positions currently in the "pop" phase (scale up before collapse)
    var poppingPositions: Set<GridPosition> = []
    var showMilestone: Bool = false

    /// Positions that were emptied by the last successful match — excluded from next spawn
    private var recentlyEmptiedPositions: Set<GridPosition> = []

    // MARK: - Tunnel Background
    /// Increments each time a round completes — drives the tunnel intensity
    var tunnelDepth: Int = 0
    /// Increments on every tile tap — drives a subtle inward pulse
    var tapPulseID: Int = 0
    /// Increments each new game — triggers background pattern re-roll
    var gameID: Int = 0

    // MARK: - Discovered Colors (for background painting)
    /// Colors the player has created through blending this session.
    /// Primaries start unlocked; new colors appear as the player blends them.
    var discoveredColorIndices: Set<Int> = [0, 16, 32]  // Red, Yellow, Blue

    // MARK: - Near-Miss Stats (for game over screen)

    var bestRound: Int {
        get { UserDefaults.standard.integer(forKey: "blent_best_round") }
        set { UserDefaults.standard.set(newValue, forKey: "blent_best_round") }
    }
    var totalBlendsThisGame: Int = 0
    var totalRoundsCompletedThisGame: Int = 0
    /// How many tiles on the board could have been blended toward the target at game over
    var nearMissBlendCount: Int = 0
    /// The closest color on the board to the target at game over (wheel distance)
    var closestColorDistance: Int = 0
    var closestColorOnBoard: PrismColor? = nil

    // MARK: - Lives

    var lives: Int = 3
    /// Tracks how many lives were lost since the last bonus-life checkpoint
    private var livesLostInStreak: Int = 0
    /// The round at which we last awarded (or started tracking) a bonus life
    private var streakCheckpointRound: Int = 0

    /// Whether the player can spend a life to retry the current round
    var canUseLife: Bool { lives > 0 && isGameOver }

    // MARK: - Undo

    private var undoGrid: [[PrismColor?]]? = nil
    private var undoScore: Int? = nil
    var canUndo: Bool { undoGrid != nil }
    private var undoUsedThisRound: Bool = false

    // MARK: - Settings

    var showColorLabels: Bool {
        get {
            // Default to ON for new players
            if UserDefaults.standard.object(forKey: "blent_show_labels") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "blent_show_labels")
        }
        set { UserDefaults.standard.set(newValue, forKey: "blent_show_labels") }
    }

    // MARK: - First-Round Hint

    var hintPositions: Set<GridPosition> = []
    var showMergeHint: Bool = false

    // MARK: - Hint Tokens (earned from rewarded ads)

    /// Persistent hint token count
    var hintTokens: Int {
        get { UserDefaults.standard.integer(forKey: "blent_hint_tokens") }
        set { UserDefaults.standard.set(newValue, forKey: "blent_hint_tokens") }
    }

    /// Whether the hint highlight is currently active this round
    var hintActive: Bool = false

    /// Use a hint token: highlights the best pair to blend toward the target.
    /// Returns true if a hint was successfully shown.
    @discardableResult
    func useHintToken() -> Bool {
        guard hintTokens > 0, !isGameOver, !isProcessing, targetColor != nil else { return false }
        guard let bestPair = findBestBlendPair() else { return false }

        hintTokens -= 1
        hintPositions = Set(bestPair)
        hintActive = true
        HapticManager.tilePlaced()
        SoundManager.shared.playSelect()
        return true
    }

    /// Find the pair of tiles on the board whose blend result is closest to the target.
    private func findBestBlendPair() -> [GridPosition]? {
        guard let target = targetColor else { return nil }

        var bestDist = Int.max
        var bestPair: [GridPosition]? = nil

        let occupied: [(GridPosition, PrismColor)] = (0..<gridSize).flatMap { r in
            (0..<gridSize).compactMap { c in
                guard let color = grid[r][c] else { return nil }
                return (GridPosition(row: r, col: c), color)
            }
        }

        for i in 0..<occupied.count {
            for j in (i+1)..<occupied.count {
                let (posA, colorA) = occupied[i]
                let (posB, colorB) = occupied[j]
                let result = PrismColor.mix(colorA, colorB)
                let diff = abs(result.wheelIndex - target.wheelIndex)
                let dist = min(diff, PrismColor.wheelSize - diff)
                if dist < bestDist {
                    bestDist = dist
                    bestPair = [posA, posB]
                }
            }
        }

        return bestPair
    }

    /// Grant a reward from watching an ad
    enum RewardType: CaseIterable {
        case extraLife
        case hintToken
    }

    /// Grant a random reward. Returns what was granted.
    func grantReward() -> RewardType {
        // Weight toward what the player needs more
        let needsLife = lives <= 1
        let needsHint = hintTokens <= 0
        let reward: RewardType

        if needsLife && !needsHint {
            reward = .extraLife
        } else if needsHint && !needsLife {
            reward = .hintToken
        } else {
            // Random 50/50
            reward = RewardType.allCases.randomElement()!
        }

        switch reward {
        case .extraLife:
            lives += 1
        case .hintToken:
            hintTokens += 1
        }

        return reward
    }

    // MARK: - Multi-Step Targets

    /// Remaining targets after the current one (for multi-step rounds)
    var pendingTargets: [PrismColor] = []
    /// Total targets this round (for progress display)
    var totalTargetsThisRound: Int = 1
    /// Which target we're on (1-based for display)
    var currentTargetNumber: Int { totalTargetsThisRound - pendingTargets.count }
    /// Brief overlay when hitting a sub-target
    var showSubTargetComplete: Bool = false

    var targetCountForRound: Int { 1 }

    // MARK: - Poison Tiles (disabled — zen mode)

    var poisonPositions: Set<GridPosition> = []
    var showPoisonIntro: Bool = false
    var hasSeenPoisonIntro: Bool {
        get { UserDefaults.standard.bool(forKey: "blent_seen_poison") }
        set { UserDefaults.standard.set(newValue, forKey: "blent_seen_poison") }
    }

    var poisonTileCount: Int { 0 }

    // MARK: - Achievement Unlock Tracking

    /// Achievements unlocked during the current round/game-over — shown on the overlay card
    var recentlyUnlockedAchievements: [StatsManager.Achievement] = []

    /// Toast queue: achievement currently being shown as a floating toast (top-right corner)
    var achievementToast: StatsManager.Achievement? = nil

    // MARK: - Golden Tiles & Multiplier System

    /// Positions of golden bonus tiles on the board
    var goldenPositions: Set<GridPosition> = []
    /// Rounds remaining with active multiplier (0 = inactive)
    var multiplierRoundsLeft: Int = 0
    /// The multiplier value (3 for golden tiles, 5 for Untouchable)
    var multiplierValue: Int = 3
    /// Whether any multiplier is active
    var isMultiplierActive: Bool { multiplierRoundsLeft > 0 }
    /// Current score multiplier
    var scoreMultiplier: Int { multiplierRoundsLeft > 0 ? multiplierValue : 1 }

    /// What type of multiplier is active (drives visual effects)
    enum MultiplierSource: Equatable {
        case none
        case golden    // 3x — warm gold glow
        case untouchable // 5x — red glow
    }
    var activeMultiplierSource: MultiplierSource = .none

    // MARK: - Invisible DDA & Breather Rounds

    /// Consecutive game-overs without completing a round (persists across newGame)
    private var consecutiveDeaths: Int = 0
    /// Consecutive rounds completed without dying (resets on game over)
    private var consecutiveWins: Int = 0
    /// Prevents back-to-back breather rounds
    private var lastRoundWasBreather: Bool = false

    /// Whether this round got DDA assistance (for debugging, not exposed to UI)
    private(set) var ddaActive: Bool = false

    // MARK: - Background Frenzy

    /// When > 0, the background animates wildly. Decrements each round.
    var backgroundFrenzyRoundsLeft: Int = 0
    var isBackgroundFrenzy: Bool { backgroundFrenzyRoundsLeft > 0 }

    // MARK: - Near-Miss Proximity Feedback

    enum ProximityHint: Equatable {
        case hot       // 1 step away
        case warm      // 2 steps away
        case close     // 3–4 steps away

        var label: String {
            switch self {
            case .hot:   return "So close!"
            case .warm:  return "Getting warm..."
            case .close: return "On the right track"
            }
        }
    }
    /// Set briefly after each blend to show how close the result is to the target
    var proximityHint: ProximityHint? = nil
    /// Position where the hint should appear (the blend result tile)
    var proximityHintPosition: GridPosition? = nil

    /// Snapshot badges before a stats event, then diff after to find new unlocks
    private func captureNewAchievements(around action: () -> Void) {
        let before = StatsManager.shared.unlockedBadges
        action()
        let after = StatsManager.shared.unlockedBadges
        let newIDs = after.subtracting(before)
        if !newIDs.isEmpty {
            let newOnes = StatsManager.allAchievements.filter { newIDs.contains($0.id) }
            recentlyUnlockedAchievements.append(contentsOf: newOnes)
            // Show toast + meow for first new achievement
            showAchievementToasts(newOnes)
        }
    }

    /// Show each unlocked achievement as a sequential toast with meow (max 3 shown)
    private func showAchievementToasts(_ achievements: [StatsManager.Achievement]) {
        let toShow = Array(achievements.prefix(3))
        Task {
            for achievement in toShow {
                achievementToast = achievement
                SoundManager.shared.playMeow()
                HapticManager.tilePlaced()
                try? await Task.sleep(for: .milliseconds(1500))
                achievementToast = nil
                if toShow.count > 1 {
                    try? await Task.sleep(for: .milliseconds(200))
                }
            }
        }
    }

    // MARK: - Combo / Par System

    var blendsThisTarget: Int = 0
    var parForCurrentTarget: Int = 0
    var comboMessage: String? = nil
    var comboBonusTotal: Int = 0
    /// Score breakdown for the round complete overlay
    var lastRoundBlendPoints: Int = 0
    var lastRoundMatchBonus: Int = 0
    var lastRoundComboBonus: Int = 0
    /// Mercy system: if the player didn't get a perfect mix last round,
    /// the next round drops to depth-1 (two primaries → secondary).
    /// Active until round 50+, when full difficulty always applies.
    var lastRoundWasPerfect: Bool = true

    // MARK: - Bonus System

    /// Describes a bonus earned on round complete
    struct EarnedBonus: Equatable {
        let type: BonusType
        let points: Int           // 0 if this is a multiplier-only bonus
        let isMultiplier: Bool    // true = activates a multiplier instead of flat points

        static func == (lhs: EarnedBonus, rhs: EarnedBonus) -> Bool {
            lhs.type == rhs.type && lhs.points == rhs.points
        }
    }

    enum BonusType: Equatable {
        case perfectBlend   // 1-blend match → flat +150
        case efficient      // par blends → flat +100
        case cleanStreak    // 3 rounds no undo → flat +75
        case speedDemon     // < 5 sec → flat +50
        case untouchable    // 15 rounds no life → 5x multiplier

        var label: String {
            switch self {
            case .perfectBlend: return "Perfect Mix!"
            case .efficient:    return "Efficient!"
            case .cleanStreak:  return "Clean Streak!"
            case .speedDemon:   return "Speed Demon!"
            case .untouchable:  return "UNTOUCHABLE"
            }
        }

        /// Each bonus has a distinct color
        var hexColor: UInt {
            switch self {
            case .perfectBlend: return 0xFF6B9D  // pink — rare & special
            case .efficient:    return 0x7BCF72  // green — clean
            case .cleanStreak:  return 0xB8A9E8  // lavender — steady
            case .speedDemon:   return 0xFFB800  // yellow — fast
            case .untouchable:  return 0xE83A3A  // red — powerful
            }
        }

        var sfIcon: String {
            switch self {
            case .perfectBlend: return "sparkles"
            case .efficient:    return "checkmark.seal.fill"
            case .cleanStreak:  return "flame.fill"
            case .speedDemon:   return "bolt.fill"
            case .untouchable:  return "shield.fill"
            }
        }
    }

    /// Consecutive rounds completed without using undo
    var cleanRoundStreak: Int = 0
    /// Timestamp of first blend this round (for speed bonus)
    var firstBlendTime: Date? = nil
    /// Colors created for the first time this game (for explorer bonus)
    var newColorsThisGame: Set<Int> = []
    /// Rounds survived without losing a life (for untouchable)
    var roundsWithoutDying: Int = 0
    /// The most impressive bonus earned this round (drives the floating label)
    var lastEarnedBonus: EarnedBonus? = nil
    /// Trigger for bonus animation
    var bonusTrigger: Int = 0

    // MARK: - Floating Score Animation
    /// Total points earned on last round complete (triggers floating "+X" text)
    var floatingPointsAmount: Int = 0
    /// Multiplier active when those points were earned (1 = none, 3 = golden)
    var floatingPointsMultiplier: Int = 1
    /// Toggled to trigger the floating points animation
    var floatingPointsTrigger: Int = 0
    /// The color of the target that was just matched (for coloring the floating text)
    var floatingPointsColor: Color = .gray

    // MARK: - Tutorial / Notification System
    /// Current notification text to show (nil = hidden)
    var notificationText: String? = nil
    /// Trigger to animate notification appearance
    var notificationTrigger: Int = 0
    /// Whether to show arrow pointers at hinted tiles (round 1 tutorial)
    var showTutorialArrows: Bool = false
    /// Incremented on each round complete — used to trigger celebration cats
    var completedRoundCount: Int = 0

    // MARK: - Difficulty Scaling

    /// Maximum target depth for the current tier (what colors can be targets)
    var maxTargetDepth: Int {
        if round <= 10 { return 1 }   // Tier 1: primaries → secondaries
        if round <= 20 { return 2 }   // Tier 2: + depth 2 targets
        if round <= 30 { return 3 }   // Tier 3: + depth 3 targets
        return 4                       // Tier 4+: full 48-color palette
    }

    /// Maximum tile depth for distractors (what colors appear on the board)
    var maxTileDepth: Int {
        if round <= 10 { return 0 }   // Only primaries as distractors
        if round <= 20 { return 1 }   // + secondaries
        if round <= 30 { return 2 }   // + depth 2 colors
        if round <= 40 { return 3 }   // + depth 3 colors
        return 4                       // Full palette
    }

    /// Colors available as distractor tiles for the current tier
    var availableDistractorColors: [PrismColor] {
        PrismColor.allColors.filter { $0.depth <= maxTileDepth }
    }

    var distractorCount: Int {
        if round <= 2 { return 0 }
        if round <= 5 { return 1 }
        if round <= 10 { return 2 }
        if round <= 15 { return 3 }
        if round <= 20 { return 4 }
        if round <= 30 { return 5 }
        return min(6 + (round - 30) / 10, 8)
    }

    // MARK: - Init

    init() {
        grid = Array(repeating: Array(repeating: nil, count: GridPosition.gridSize),
                     count: GridPosition.gridSize)
        startNewRound()
    }

    // MARK: - Blend Preview

    /// When a tile is selected, shows what blending it with any other tile would produce.
    /// Nil when no tile is selected.
    var selectedColor: PrismColor? {
        guard let pos = selectedPosition else { return nil }
        return tile(at: pos)
    }

    /// Preview the result of blending the selected tile with the given color.
    func previewBlend(with other: PrismColor) -> PrismColor? {
        guard let sel = selectedColor else { return nil }
        return PrismColor.mix(sel, other)
    }

    // MARK: - Queries

    func tile(at pos: GridPosition) -> PrismColor? {
        guard pos.row >= 0, pos.row < gridSize,
              pos.col >= 0, pos.col < gridSize else { return nil }
        return grid[pos.row][pos.col]
    }

    func isEmpty(at pos: GridPosition) -> Bool {
        tile(at: pos) == nil
    }

    func emptyPositions() -> [GridPosition] {
        var result: [GridPosition] = []
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if grid[r][c] == nil {
                    result.append(GridPosition(row: r, col: c))
                }
            }
        }
        return result
    }

    func adjacentPositions(to pos: GridPosition) -> [GridPosition] {
        [(-1, 0), (1, 0), (0, -1), (0, 1)].compactMap { dr, dc in
            let p = GridPosition(row: pos.row + dr, col: pos.col + dc)
            guard p.row >= 0, p.row < gridSize,
                  p.col >= 0, p.col < gridSize else { return nil }
            return p
        }
    }

    func hasAnyBlend() -> Bool {
        var count = 0
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if grid[r][c] != nil {
                    count += 1
                    if count >= 2 { return true }
                }
            }
        }
        return false
    }

    /// Called on any game-over to update DDA tracking
    private func recordDeath() {
        consecutiveDeaths += 1
        consecutiveWins = 0
        roundsWithoutDying = 0  // reset untouchable streak
    }

    /// Called on any round completion to update DDA tracking
    private func recordWin() {
        consecutiveWins += 1
        consecutiveDeaths = 0
    }

    // MARK: - Tile Selection & Blending

    func selectTile(at pos: GridPosition) {
        guard !isProcessing, !isGameOver, !showSubTargetComplete else { return }
        guard tile(at: pos) != nil else {
            selectedPosition = nil
            return
        }

        // tapPulseID += 1  // disabled — zen mode (no per-tap background jitter)

        // Poison tiles disabled — zen mode

        if showMergeHint {
            hintPositions = []
            showMergeHint = false
        }

        // Dismiss tutorial on first tap
        if showTutorialArrows {
            showTutorialArrows = false
            notificationText = nil
        }

        if let sel = selectedPosition {
            if sel == pos {
                selectedPosition = nil
            } else if tile(at: sel) != nil {
                performBlend(sel, pos)
            } else {
                HapticManager.tilePlaced()
                SoundManager.shared.playSelect()
                selectedPosition = pos
            }
        } else {
            HapticManager.tilePlaced()
            SoundManager.shared.playSelect()
            selectedPosition = pos
        }
    }

    private func performBlend(_ posA: GridPosition, _ posB: GridPosition) {
        guard let colorA = tile(at: posA),
              let colorB = tile(at: posB) else { return }

        isProcessing = true
        selectedPosition = nil
        proximityHint = nil
        proximityHintPosition = nil
        let result = PrismColor.mix(colorA, colorB)

        if !undoUsedThisRound {
            undoGrid = grid.map { $0 }
            undoScore = score
        }

        // Phase 1: Pop both tiles up
        poppingPositions = [posA, posB]

        Task {
            // Hold the pop for a beat
            try? await Task.sleep(for: .milliseconds(100))

            // Phase 2: Collapse into result
            poppingPositions = []
            blendingPositions = (posA, posB)

            try? await Task.sleep(for: .milliseconds(80))

            HapticManager.blend()
            // Skip the blend tone on a winning match — let the round-complete sound play clean
            let isMatch = targetColor != nil && result == targetColor!
            if !isMatch {
                SoundManager.shared.playBlendTone(for: result)
            }

            grid[posA.row][posA.col] = result
            grid[posB.row][posB.col] = nil
            poisonPositions.remove(posA)
            poisonPositions.remove(posB)

            // Check if a golden tile was used — activate 3x multiplier
            let usedGolden = goldenPositions.contains(posA) || goldenPositions.contains(posB)
            goldenPositions.remove(posA)
            goldenPositions.remove(posB)
            if usedGolden {
                activateMultiplier(value: 3, rounds: 3, source: .golden)
                StatsManager.shared.recordGoldenTileUsed()
            }

            blendingPositions = nil
            lastBlendPosition = posA

            // Track this color as discovered — feeds into background canvas
            discoveredColorIndices.insert(result.wheelIndex)

            // Track first blend time for speed bonus
            if firstBlendTime == nil {
                firstBlendTime = Date()
            }

            // Color Explorer: +25 for creating a color new to this game
            if !newColorsThisGame.contains(result.wheelIndex) {
                newColorsThisGame.insert(result.wheelIndex)
                let explorerBonus = 25 * scoreMultiplier
                score += explorerBonus
            }

            score += 10 * scoreMultiplier
            blendsThisTarget += 1
            totalBlendsThisGame += 1

            // Check if result matches current target
            if let target = targetColor, result == target {
                // Stop the timer immediately on match — prevents expiry during overlays
                stopTimer()

                matchedPosition = posA
                let roundBonus = round * 50 * scoreMultiplier
                score += roundBonus

                // Track breakdown
                lastRoundBlendPoints = blendsThisTarget * 10
                lastRoundMatchBonus = roundBonus

                lastRoundComboBonus = 0

                updateHighScore()
                try? await Task.sleep(for: .milliseconds(250))
                HapticManager.lineClear()

                // Remove matched tile and track emptied positions
                grid[posA.row][posA.col] = nil
                recentlyEmptiedPositions = [posA, posB]
                matchedPosition = nil
                lastBlendPosition = nil

                // Round complete (non-blocking)
                captureNewAchievements {
                    StatsManager.shared.recordRoundComplete(
                        colorName: target.name,
                        blendsUsed: blendsThisTarget,
                        par: 0,
                        isMultiTarget: false
                    )
                }
                let completedRound = round
                let isMilestone = completedRound % 4 == 0 && completedRound > 0
                if isMilestone {
                    SoundManager.shared.playMilestone()
                } else {
                    SoundManager.shared.playRoundComplete()
                }

                // Track whether this round was perfect (1 blend) for mercy system
                lastRoundWasPerfect = (blendsThisTarget == 1)

                // Evaluate round bonuses (perfect blend, efficiency, streak, speed)
                let roundBonuses = evaluateBonuses()
                updateHighScore()  // re-check after bonuses

                // Trigger floating points animation (non-blocking)
                let totalEarned = lastRoundBlendPoints + lastRoundMatchBonus + lastRoundComboBonus + roundBonuses
                floatingPointsAmount = totalEarned
                floatingPointsMultiplier = scoreMultiplier
                floatingPointsColor = target.color
                floatingPointsTrigger += 1
                completedRoundCount += 1

                // Reset per-round tracking
                firstBlendTime = nil

                tunnelDepth += 1

                // Brief pause for visual match feedback, then immediately continue
                try? await Task.sleep(for: .milliseconds(350))

                guard !isGameOver else {
                    isProcessing = false
                    return
                }

                startNewRound()
                isProcessing = false
            } else {
                // Near-miss proximity feedback
                if let target = targetColor {
                    let diff = abs(result.wheelIndex - target.wheelIndex)
                    let dist = min(diff, PrismColor.wheelSize - diff)
                    let hint: ProximityHint? = switch dist {
                        case 1...2:  .hot
                        case 3...4:  .warm
                        case 5...8:  .close
                        default:     nil
                    }
                    if let hint {
                        proximityHint = hint
                        proximityHintPosition = posA
                    }
                }

                try? await Task.sleep(for: .milliseconds(120))
                lastBlendPosition = nil
                checkGameOver()
                isProcessing = false

                // 1/3 chance: remind player a combo still exists
                if !isGameOver && Int.random(in: 0..<3) == 0 {
                    if findBestBlendPair() != nil {
                        notificationText = "A working combo is on the board"
                        notificationTrigger += 1
                    }
                }

                // Clear proximity hint after player has seen it (non-blocking)
                if proximityHint != nil {
                    try? await Task.sleep(for: .milliseconds(1000))
                    proximityHint = nil
                    proximityHintPosition = nil
                }
            }
        }
    }

    // MARK: - Overlay Dismissal

    func dismissRoundComplete() {
        guard showRoundComplete, roundCompleteCanDismiss else { return }
        showRoundComplete = false
        showMilestone = false
        comboMessage = nil
        recentlyUnlockedAchievements = []
        isProcessing = false
        startNewRound()
    }

    // MARK: - Combo Evaluation

    /// Returns a combo message string if the player earned one, and adds bonus points.
    private func evaluateCombo() -> String? {
        if parForCurrentTarget <= 0 { return nil }

        if blendsThisTarget < parForCurrentTarget {
            let bonus = 200 * scoreMultiplier
            score += bonus
            comboBonusTotal += bonus
            return "UNDER PAR! +\(bonus)"
        } else if blendsThisTarget == parForCurrentTarget {
            let bonus = 100 * scoreMultiplier
            score += bonus
            comboBonusTotal += bonus
            return "PAR! +\(bonus)"
        }
        return nil
    }

    // MARK: - Multiplier Activation

    /// Activate a score multiplier. Higher multipliers always win over lower ones.
    func activateMultiplier(value: Int, rounds: Int, source: MultiplierSource) {
        // Only override if the new multiplier is stronger or the current one expired
        if value > multiplierValue || multiplierRoundsLeft == 0 {
            multiplierValue = value
            multiplierRoundsLeft = rounds
            activeMultiplierSource = source
        } else if value == multiplierValue {
            // Same tier — just refresh duration
            multiplierRoundsLeft = max(multiplierRoundsLeft, rounds)
        }
    }

    // MARK: - Bonus Evaluation

    /// Evaluate all round-complete bonuses. Returns total flat bonus points awarded.
    /// Multiplier bonuses don't add points directly — they activate a multiplier.
    private func evaluateBonuses() -> Int {
        var totalBonus = 0
        var earned: [EarnedBonus] = []

        // ── Flat point bonuses (common) ──

        // 1. Perfect Blend: matched target in exactly 1 blend
        if blendsThisTarget == 1 {
            let bonus = 150 * scoreMultiplier
            totalBonus += bonus
            earned.append(EarnedBonus(type: .perfectBlend, points: bonus, isMultiplier: false))
        }

        // 2. Efficiency: matched in minimum blends (par) — only when > 1 blend
        if blendsThisTarget > 1 && parForCurrentTarget > 0 && blendsThisTarget <= parForCurrentTarget {
            let bonus = 100 * scoreMultiplier
            totalBonus += bonus
            earned.append(EarnedBonus(type: .efficient, points: bonus, isMultiplier: false))
        }

        // 3. No-Undo Streak: every 3 clean rounds
        if !undoUsedThisRound {
            cleanRoundStreak += 1
        } else {
            cleanRoundStreak = 0
        }
        if cleanRoundStreak >= 3 && cleanRoundStreak % 3 == 0 {
            let bonus = 75 * scoreMultiplier
            totalBonus += bonus
            earned.append(EarnedBonus(type: .cleanStreak, points: bonus, isMultiplier: false))
        }

        // 4. Speed Demon: completed within 5 seconds of first blend
        if let startTime = firstBlendTime {
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed <= 5.0 && blendsThisTarget >= 1 {
                let bonus = 50 * scoreMultiplier
                totalBonus += bonus
                earned.append(EarnedBonus(type: .speedDemon, points: bonus, isMultiplier: false))
            }
        }

        // ── Multiplier bonuses (rare, hard to get) ──

        // 5. Untouchable: 15 rounds without losing a life → 5x for 3 rounds
        roundsWithoutDying += 1
        if roundsWithoutDying >= 15 && roundsWithoutDying % 15 == 0 {
            activateMultiplier(value: 5, rounds: 3, source: .untouchable)
            earned.append(EarnedBonus(type: .untouchable, points: 0, isMultiplier: true))
        }

        // Apply flat bonus points
        if totalBonus > 0 {
            score += totalBonus
        }

        // Show the most impressive bonus (multipliers > flat, then by rarity)
        // Priority: untouchable > perfect > efficient > speed > clean
        let priority: [BonusType] = [.untouchable, .perfectBlend, .efficient, .speedDemon, .cleanStreak]
        let best = priority.compactMap { type in earned.first { $0.type == type } }.first

        if let best {
            lastEarnedBonus = best
            bonusTrigger += 1
        }

        return totalBonus
    }

    // MARK: - Undo Action

    func undoLastBlend() {
        guard let savedGrid = undoGrid, let savedScore = undoScore else { return }
        grid = savedGrid
        score = savedScore
        undoGrid = nil
        undoScore = nil
        undoUsedThisRound = true
        StatsManager.shared.recordUndo()
        lastBlendPosition = nil
        selectedPosition = nil
        if blendsThisTarget > 0 { blendsThisTarget -= 1 }
    }

    // MARK: - Round Management

    func startNewRound() {
        // Track completed rounds (skip on first call from init)
        if round > 0 {
            totalRoundsCompletedThisGame += 1
            if round > bestRound { bestRound = round }
            recordWin()
            checkBonusLife()
        }
        round += 1
        selectedPosition = nil
        undoGrid = nil
        undoScore = nil
        undoUsedThisRound = false
        comboBonusTotal = 0
        comboMessage = nil
        goldenPositions = []
        hintActive = false

        // Decrement score multiplier
        if multiplierRoundsLeft > 0 {
            multiplierRoundsLeft -= 1
            if multiplierRoundsLeft == 0 {
                activeMultiplierSource = .none
            }
        }

        // ── Breather round? ──
        // After round 4, ~20% random chance, never back-to-back
        let isBreather = round > 4 && !lastRoundWasBreather && Double.random(in: 0...1) < 0.20
        lastRoundWasBreather = isBreather

        // Background frenzy disabled — zen mode
        backgroundFrenzyRoundsLeft = 0

        // ── DDA: invisible difficulty assist for struggling players ──
        // Active after 2+ consecutive deaths. Adds one helpful tile to the board.
        let ddaHelp = consecutiveDeaths >= 2
        ddaActive = ddaHelp

        // ── Target depth: mercy system + breather rounds use simpler colors ──
        // If the player didn't get a perfect mix last round (and round < 50),
        // drop to depth 1 (two primaries → secondary) so they stay engaged.
        let mercyActive = !lastRoundWasPerfect && round < 50
        let effectiveMaxDepth: Int
        if isBreather || mercyActive {
            effectiveMaxDepth = min(maxTargetDepth, 1)
        } else {
            effectiveMaxDepth = maxTargetDepth
        }

        // Determine how many targets this round
        let targetCount = isBreather ? 1 : targetCountForRound
        totalTargetsThisRound = targetCount

        // Generate all targets for this round
        var targets: [PrismColor] = []
        let boardColors = Set(grid.flatMap { $0 }.compactMap { $0 })
        for _ in 0..<targetCount {
            let candidates = PrismColor.targets(maxDepth: effectiveMaxDepth)
            let alreadyChosen = Set(targets)
            let preferred = candidates.filter { !boardColors.contains($0) && !alreadyChosen.contains($0) }
            if let pick = (preferred.isEmpty ? candidates.filter { !alreadyChosen.contains($0) } : preferred).randomElement() {
                targets.append(pick)
            } else if let fallback = candidates.randomElement() {
                targets.append(fallback)
            }
        }

        guard !targets.isEmpty else { return }

        // Set first target, queue the rest
        targetColor = targets[0]
        pendingTargets = Array(targets.dropFirst())

        // Reset the board every round — fresh slate prevents tile buildup
        // and same-spot clustering from previous rounds
        grid = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
        recentlyEmptiedPositions = []

        // Spawn ingredients for first target
        if !spawnIngredientsForCurrentTarget() { return }

        // ── DDA helper tile ──
        // Replace one distractor slot with a useful ingredient (one of the target's directPair).
        // For depth-3 targets this often spawns the intermediate color — a big invisible boost.
        var ddaUsedSlot = false
        if ddaHelp, let target = targetColor,
           let (pairA, pairB) = PrismColor.directPair[target.wheelIndex] {
            let helpColor = [pairA, pairB].randomElement()!
            if let pos = emptyPositions().randomElement() {
                grid[pos.row][pos.col] = helpColor
                ddaUsedSlot = true
            }
        }

        // Spawn primary distractors (breather halves them, DDA may claim one slot)
        var numDistractors = isBreather ? distractorCount / 2 : distractorCount
        if ddaUsedSlot { numDistractors = max(0, numDistractors - 1) }
        numDistractors = min(numDistractors, emptyPositions().count)
        for _ in 0..<numDistractors {
            if let pos = emptyPositions().randomElement() {
                grid[pos.row][pos.col] = availableDistractorColors.randomElement()!
            }
        }

        // Poison tiles disabled — zen mode
        poisonPositions = []

        // First round: highlight ingredient tiles
        // (hintPositions set in spawnIngredientsForCurrentTarget for round 1)

        // ── Golden tiles: ~15% chance per round after round 3, spawn 1 on a random existing tile ──
        if round > 3 && !isBreather && Double.random(in: 0...1) < 0.15 {
            // Pick a random occupied tile to make golden
            let occupiedPositions = (0..<gridSize).flatMap { r in
                (0..<gridSize).compactMap { c -> GridPosition? in
                    let pos = GridPosition(row: r, col: c)
                    guard grid[r][c] != nil else { return nil }
                    return pos
                }
            }
            if let goldenPos = occupiedPositions.randomElement() {
                goldenPositions.insert(goldenPos)
            }
        }

        // Start round timer (round 15+)
        startTimer()
    }

    /// Spawn ingredients for the current target. Returns false if game over (no room).
    @discardableResult
    private func spawnIngredientsForCurrentTarget() -> Bool {
        guard let target = targetColor else { return false }

        let ingredients = PrismColor.optimalIngredients[target.wheelIndex] ?? [target]

        // Set par for combo tracking
        parForCurrentTarget = ingredients.count - 1
        blendsThisTarget = 0

        let emptyCount = emptyPositions().count
        if emptyCount < ingredients.count {
            stopTimer()
            computeNearMissStats()
            if round > bestRound { bestRound = round }
            updateHighScore()
            recordDeath()
            isGameOver = true
            captureNewAchievements {
                StatsManager.shared.recordGameOver(round: round, blends: totalBlendsThisGame, score: score, diedToPoison: false)
            }
            HapticManager.gameOver()
            SoundManager.shared.playGameOver()
            return false
        }

        let placed = spawnConnectedCluster(tiles: ingredients.shuffled())

        if round == 1 {
            hintPositions = Set(placed)
            showMergeHint = true
            showTutorialArrows = true
            notificationText = "Tap both colors to create the target above"
            notificationTrigger += 1
        } else {
            hintPositions = []
            showMergeHint = false
            showTutorialArrows = false
        }

        return true
    }

    /// Advance to the next target in a multi-step round.
    private func advanceToNextTarget() {
        guard !pendingTargets.isEmpty else { return }
        targetColor = pendingTargets.removeFirst()
        undoGrid = nil
        undoScore = nil
        undoUsedThisRound = false

        // Restart the timer for the next sub-target so the player gets fresh time
        startTimer()

        spawnIngredientsForCurrentTarget()
    }

    @discardableResult
    private func spawnConnectedCluster(tiles: [PrismColor]) -> [GridPosition] {
        guard !tiles.isEmpty else { return [] }
        let empty = emptyPositions()
        guard !empty.isEmpty else { return [] }

        var placed: [GridPosition] = []

        if round <= 2 && empty.count > tiles.count + 4 {
            // Early rounds only: cluster tiles near each other so new players
            // can see they're related. After round 2, always scatter.
            guard let start = empty.randomElement() else { return [] }
            grid[start.row][start.col] = tiles[0]
            placed.append(start)

            for i in 1..<tiles.count {
                var candidates: [GridPosition] = []
                for p in placed {
                    for adj in adjacentPositions(to: p) {
                        if isEmpty(at: adj) && !candidates.contains(adj) {
                            candidates.append(adj)
                        }
                    }
                }
                if let pos = candidates.randomElement() {
                    grid[pos.row][pos.col] = tiles[i]
                    placed.append(pos)
                } else if let fallback = emptyPositions().randomElement() {
                    grid[fallback.row][fallback.col] = tiles[i]
                    placed.append(fallback)
                }
            }
        } else {
            // Scatter mode: avoid positions that were just emptied by the last match
            // This prevents the "infinite obvious choice" loop
            let preferred = empty.filter { !recentlyEmptiedPositions.contains($0) }
            var available = (preferred.count >= tiles.count ? preferred : empty).shuffled()
            for i in 0..<tiles.count {
                guard !available.isEmpty else { break }
                let pos = available.removeFirst()
                grid[pos.row][pos.col] = tiles[i]
                placed.append(pos)
            }
        }

        // Clear after use
        recentlyEmptiedPositions = []
        return placed
    }

    // MARK: - Game Over

    private func checkGameOver() {
        if !canStillWin() {
            stopTimer()
            computeNearMissStats()
            if round > bestRound { bestRound = round }
            updateHighScore()
            recordDeath()
            isGameOver = true
            captureNewAchievements {
                StatsManager.shared.recordGameOver(round: round, blends: totalBlendsThisGame, score: score, diedToPoison: false)
            }
            HapticManager.gameOver()
            SoundManager.shared.playGameOver()
        }
    }

    /// Compute near-miss data for the game over screen.
    private func computeNearMissStats() {
        guard let target = targetColor else { return }

        // Find all colors currently on the board
        var boardColors: [PrismColor] = []
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if let tile = grid[r][c] {
                    boardColors.append(tile)
                }
            }
        }

        // Find closest color on the board to the target (by wheel distance)
        var minDist = PrismColor.wheelSize
        var closest: PrismColor? = nil
        for color in boardColors {
            let diff = abs(color.wheelIndex - target.wheelIndex)
            let dist = min(diff, PrismColor.wheelSize - diff)
            if dist < minDist {
                minDist = dist
                closest = color
            }
        }
        closestColorDistance = minDist
        closestColorOnBoard = closest

        // Count how many single blends could produce ANY result closer to target
        var helpfulBlends = 0
        for i in 0..<boardColors.count {
            for j in (i + 1)..<boardColors.count {
                let result = PrismColor.mix(boardColors[i], boardColors[j])
                let resultDiff = abs(result.wheelIndex - target.wheelIndex)
                let resultDist = min(resultDiff, PrismColor.wheelSize - resultDiff)
                if resultDist < minDist {
                    helpfulBlends += 1
                }
            }
        }
        nearMissBlendCount = helpfulBlends
    }

    func canStillWin() -> Bool {
        guard let target = targetColor else { return false }
        var colors: [Int] = []
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if let tile = grid[r][c] {
                    colors.append(tile.wheelIndex)
                }
            }
        }
        if colors.count < 2 { return false }

        var memo = Set<[Int]>()
        var nodes = 0
        return Self.searchForTarget(colors.sorted(), target: target.wheelIndex,
                                     memo: &memo, nodes: &nodes)
    }

    private static func searchForTarget(
        _ sorted: [Int], target: Int,
        memo: inout Set<[Int]>, nodes: inout Int
    ) -> Bool {
        nodes += 1
        if nodes > 50_000 { return true }
        if sorted.count < 2 { return false }
        if memo.contains(sorted) { return false }
        memo.insert(sorted)

        for i in 0..<sorted.count {
            for j in (i + 1)..<sorted.count {
                let result = PrismColor.mix(
                    PrismColor(wheelIndex: sorted[i]),
                    PrismColor(wheelIndex: sorted[j])
                ).wheelIndex

                if result == target { return true }

                var remaining: [Int] = []
                for k in 0..<sorted.count where k != i && k != j {
                    remaining.append(sorted[k])
                }
                remaining.append(result)
                remaining.sort()

                if searchForTarget(remaining, target: target,
                                   memo: &memo, nodes: &nodes) {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Score & Reset

    func updateHighScore() {
        if score > highScore { highScore = score }
    }

    /// Spend a life to restart the current round (keeps score, round number, and lives - 1)
    func useLife() {
        guard canUseLife else { return }
        lives -= 1
        StatsManager.shared.recordLifeUsed()
        // Reset the bonus-life streak — must go another clean 10 from here
        livesLostInStreak = 0
        streakCheckpointRound = round
        isGameOver = false
        selectedPosition = nil
        matchedPosition = nil
        lastBlendPosition = nil
        blendingPositions = nil
        poppingPositions = []
        proximityHint = nil
        proximityHintPosition = nil
        undoGrid = nil
        undoScore = nil
        undoUsedThisRound = false
        cleanRoundStreak = 0
        firstBlendTime = nil
        roundsWithoutDying = 0  // using a life resets untouchable streak

        // Lost a life — definitely not perfect, trigger mercy for next attempt
        lastRoundWasPerfect = false

        // Restart the same round: decrement so startNewRound increments back,
        // and also decrement totalRoundsCompletedThisGame since startNewRound will
        // increment it (but this round wasn't actually completed)
        totalRoundsCompletedThisGame = max(0, totalRoundsCompletedThisGame - 1)
        round -= 1
        startNewRound()
    }

    /// Called when a round completes successfully — checks for bonus life every 10 rounds
    private func checkBonusLife() {
        let roundsSinceCheckpoint = round - streakCheckpointRound
        if roundsSinceCheckpoint >= 10 && livesLostInStreak == 0 {
            lives += 1
            StatsManager.shared.recordBonusLifeEarned()
            streakCheckpointRound = round
            // Reset for next streak
            livesLostInStreak = 0
        }
    }

    // MARK: - Timer (disabled — zen mode)

    func startTimer() { /* timer removed */ }
    func stopTimer() { /* timer removed */ }

    func newGame() {
        stopTimer()
        grid = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
        round = 0
        score = 0
        isGameOver = false
        selectedPosition = nil
        isProcessing = false
        showRoundComplete = false
        matchedPosition = nil
        lastBlendPosition = nil
        blendingPositions = nil
        poppingPositions = []
        cleanRoundStreak = 0
        firstBlendTime = nil
        newColorsThisGame = []
        roundsWithoutDying = 0
        lastEarnedBonus = nil
        showMilestone = false
        undoGrid = nil
        undoScore = nil
        undoUsedThisRound = false
        hintPositions = []
        showMergeHint = false
        hintActive = false
        notificationText = nil
        showTutorialArrows = false
        targetColor = nil
        pendingTargets = []
        totalTargetsThisRound = 1
        showSubTargetComplete = false
        blendsThisTarget = 0
        lastRoundWasPerfect = true  // fresh game starts optimistic
        parForCurrentTarget = 0
        comboMessage = nil
        comboBonusTotal = 0
        showPoisonIntro = false
        poisonPositions = []
        recentlyEmptiedPositions = []
        recentlyUnlockedAchievements = []
        achievementToast = nil
        proximityHint = nil
        proximityHintPosition = nil
        lives = 3
        livesLostInStreak = 0
        streakCheckpointRound = 0
        lastRoundWasBreather = false
        ddaActive = false
        backgroundFrenzyRoundsLeft = 0
        goldenPositions = []
        multiplierRoundsLeft = 0
        multiplierValue = 3
        activeMultiplierSource = .none
        timeRemaining = 0
        timerLimit = 0
        timerActive = false
        // Timer system disabled — calls to startTimer()/stopTimer() are no-ops
        // Note: consecutiveDeaths NOT reset — persists across games for DDA
        roundCompleteCanDismiss = false
        floatingPointsAmount = 0
        floatingPointsMultiplier = 1
        tunnelDepth = 0
        discoveredColorIndices = [0, 16, 32]  // reset to primaries
        gameID += 1
        totalBlendsThisGame = 0
        totalRoundsCompletedThisGame = 0
        nearMissBlendCount = 0
        closestColorDistance = 0
        closestColorOnBoard = nil
        startNewRound()
    }

    /// Dismiss the poison intro popup (called from UI)
    func dismissPoisonIntro() {
        showPoisonIntro = false
    }
}
