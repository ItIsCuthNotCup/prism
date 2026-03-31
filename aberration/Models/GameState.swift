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
    var selectedPosition: GridPosition? = nil
    var isProcessing: Bool = false
    var showRoundComplete: Bool = false
    var roundCompleteCanDismiss: Bool = false
    var matchedPosition: GridPosition? = nil
    var lastBlendPosition: GridPosition? = nil
    var blendingPositions: (GridPosition, GridPosition)? = nil
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

    // MARK: - Multi-Step Targets

    /// Remaining targets after the current one (for multi-step rounds)
    var pendingTargets: [PrismColor] = []
    /// Total targets this round (for progress display)
    var totalTargetsThisRound: Int = 1
    /// Which target we're on (1-based for display)
    var currentTargetNumber: Int { totalTargetsThisRound - pendingTargets.count }
    /// Brief overlay when hitting a sub-target
    var showSubTargetComplete: Bool = false

    var targetCountForRound: Int {
        if round < 15 { return 1 }
        if round < 25 { return 2 }
        if round < 40 { return 3 }
        return 4
    }

    // MARK: - Poison Tiles

    var poisonPositions: Set<GridPosition> = []
    var showPoisonIntro: Bool = false
    var hasSeenPoisonIntro: Bool {
        get { UserDefaults.standard.bool(forKey: "blent_seen_poison") }
        set { UserDefaults.standard.set(newValue, forKey: "blent_seen_poison") }
    }

    var poisonTileCount: Int {
        if round <= 10 { return 0 }
        return 1 + (round - 11) / 5
    }

    // MARK: - Achievement Unlock Tracking

    /// Achievements unlocked during the current round/game-over — shown on the overlay card
    var recentlyUnlockedAchievements: [StatsManager.Achievement] = []

    /// Toast queue: achievement currently being shown as a floating toast (top-right corner)
    var achievementToast: StatsManager.Achievement? = nil

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

    /// Show each unlocked achievement as a sequential toast with meow
    private func showAchievementToasts(_ achievements: [StatsManager.Achievement]) {
        Task {
            for achievement in achievements {
                achievementToast = achievement
                SoundManager.shared.playMeow()
                HapticManager.tilePlaced()
                try? await Task.sleep(for: .milliseconds(1500))
                achievementToast = nil
                // Brief gap between multiple toasts
                if achievements.count > 1 {
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

    // MARK: - Difficulty Scaling

    var maxDepth: Int {
        if round <= 3 { return 1 }
        if round <= 9 { return 2 }
        return 3
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

    // MARK: - Tile Selection & Blending

    func selectTile(at pos: GridPosition) {
        guard !isProcessing, !isGameOver, !showRoundComplete, !showSubTargetComplete else { return }
        guard tile(at: pos) != nil else {
            selectedPosition = nil
            return
        }

        tapPulseID += 1

        // Poison tile = instant game over
        if poisonPositions.contains(pos) {
            selectedPosition = nil
            computeNearMissStats()
            if round > bestRound { bestRound = round }
            updateHighScore()
            isGameOver = true
            captureNewAchievements {
                StatsManager.shared.recordGameOver(round: round, blends: totalBlendsThisGame, score: score, diedToPoison: true)
            }
            HapticManager.gameOver()
            SoundManager.shared.playGameOver()
            return
        }

        if showMergeHint {
            hintPositions = []
            showMergeHint = false
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

        blendingPositions = (posA, posB)

        Task {
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
            blendingPositions = nil
            lastBlendPosition = posA

            score += 10
            blendsThisTarget += 1
            totalBlendsThisGame += 1

            // Check if result matches current target
            if let target = targetColor, result == target {
                matchedPosition = posA
                let roundBonus = round * 50
                score += roundBonus

                // Track breakdown
                lastRoundBlendPoints = blendsThisTarget * 10
                lastRoundMatchBonus = roundBonus

                // Combo bonus
                let comboText = evaluateCombo()
                lastRoundComboBonus = comboText != nil ? (blendsThisTarget < parForCurrentTarget ? 200 : 100) : 0

                updateHighScore()
                try? await Task.sleep(for: .milliseconds(250))
                HapticManager.lineClear()

                // Remove matched tile and track emptied positions
                grid[posA.row][posA.col] = nil
                recentlyEmptiedPositions = [posA, posB]
                matchedPosition = nil
                lastBlendPosition = nil

                if !pendingTargets.isEmpty {
                    // Record stats for sub-target completion
                    captureNewAchievements {
                        StatsManager.shared.recordRoundComplete(
                            colorName: target.name,
                            blendsUsed: blendsThisTarget,
                            par: parForCurrentTarget,
                            isMultiTarget: true
                        )
                    }
                    // Multi-step: show brief sub-target overlay, then advance
                    if let ct = comboText {
                        comboMessage = ct
                    }
                    SoundManager.shared.playRoundComplete()

                    showSubTargetComplete = true
                    try? await Task.sleep(for: .milliseconds(600))
                    showSubTargetComplete = false
                    comboMessage = nil

                    advanceToNextTarget()
                    isProcessing = false
                } else {
                    // Final (or only) target — full round complete
                    // Record stats for the completed target
                    captureNewAchievements {
                        StatsManager.shared.recordRoundComplete(
                            colorName: target.name,
                            blendsUsed: blendsThisTarget,
                            par: parForCurrentTarget,
                            isMultiTarget: totalTargetsThisRound > 1
                        )
                    }
                    let completedRound = round
                    let isMilestone = completedRound % 4 == 0 && completedRound > 0
                    if isMilestone {
                        SoundManager.shared.playMilestone()
                    } else {
                        SoundManager.shared.playRoundComplete()
                    }

                    if let ct = comboText {
                        comboMessage = ct
                    }

                    showMilestone = isMilestone
                    showRoundComplete = true
                    tunnelDepth += 1
                    roundCompleteCanDismiss = false

                    // Allow dismiss after a brief minimum display
                    try? await Task.sleep(for: .milliseconds(200))
                    roundCompleteCanDismiss = true

                    // Auto-dismiss after full duration if not tapped
                    try? await Task.sleep(for: .milliseconds(isMilestone ? 1200 : 600))

                    if showRoundComplete {
                        showRoundComplete = false
                        showMilestone = false
                        comboMessage = nil
                        startNewRound()
                    }
                    isProcessing = false
                }
            } else {
                // Near-miss proximity feedback
                if let target = targetColor {
                    let diff = abs(result.wheelIndex - target.wheelIndex)
                    let dist = min(diff, 24 - diff)
                    let hint: ProximityHint? = switch dist {
                        case 1:    .hot
                        case 2:    .warm
                        case 3...4: .close
                        default:   nil
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
            let bonus = 200
            score += bonus
            comboBonusTotal += bonus
            return "UNDER PAR! +\(bonus)"
        } else if blendsThisTarget == parForCurrentTarget {
            let bonus = 100
            score += bonus
            comboBonusTotal += bonus
            return "PAR! +\(bonus)"
        }
        return nil
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
            checkBonusLife()
        }
        round += 1
        selectedPosition = nil
        undoGrid = nil
        undoScore = nil
        undoUsedThisRound = false
        comboBonusTotal = 0
        comboMessage = nil

        // Determine how many targets this round
        let targetCount = targetCountForRound
        totalTargetsThisRound = targetCount

        // Generate all targets for this round
        var targets: [PrismColor] = []
        let boardColors = Set(grid.flatMap { $0 }.compactMap { $0 })
        for _ in 0..<targetCount {
            let candidates = PrismColor.targets(maxDepth: maxDepth)
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

        // Spawn primary distractors
        let numDistractors = min(distractorCount, emptyPositions().count)
        for _ in 0..<numDistractors {
            if let pos = emptyPositions().randomElement() {
                grid[pos.row][pos.col] = PrismColor.primaries.randomElement()!
            }
        }

        // Spawn poison tiles (non-primary distractors) after round 10
        poisonPositions = []
        if poisonTileCount > 0 {
            // Show intro popup the first time
            if !hasSeenPoisonIntro {
                showPoisonIntro = true
                hasSeenPoisonIntro = true
            }

            let numPoison = min(poisonTileCount, emptyPositions().count)
            let poisonCandidates = PrismColor.allColors.filter { !$0.isPrimary }
            for _ in 0..<numPoison {
                if let pos = emptyPositions().randomElement(),
                   let poison = poisonCandidates.randomElement() {
                    grid[pos.row][pos.col] = poison
                    poisonPositions.insert(pos)
                }
            }
        }

        // First round: highlight ingredient tiles
        // (hintPositions set in spawnIngredientsForCurrentTarget for round 1)
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
            computeNearMissStats()
            if round > bestRound { bestRound = round }
            updateHighScore()
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
        } else {
            hintPositions = []
            showMergeHint = false
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
            computeNearMissStats()
            if round > bestRound { bestRound = round }
            updateHighScore()
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
        var minDist = 24
        var closest: PrismColor? = nil
        for color in boardColors {
            let diff = abs(color.wheelIndex - target.wheelIndex)
            let dist = min(diff, 24 - diff)
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
                let resultDist = min(resultDiff, 24 - resultDiff)
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
        // Reset the bonus-life streak — must go another clean 10 from here
        livesLostInStreak = 0
        streakCheckpointRound = round
        isGameOver = false
        selectedPosition = nil
        matchedPosition = nil
        lastBlendPosition = nil
        blendingPositions = nil
        proximityHint = nil
        proximityHintPosition = nil
        undoGrid = nil
        undoScore = nil
        undoUsedThisRound = false

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
            streakCheckpointRound = round
            // Reset for next streak
            livesLostInStreak = 0
        }
    }

    func newGame() {
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
        showMilestone = false
        undoGrid = nil
        undoScore = nil
        undoUsedThisRound = false
        hintPositions = []
        showMergeHint = false
        targetColor = nil
        pendingTargets = []
        totalTargetsThisRound = 1
        showSubTargetComplete = false
        blendsThisTarget = 0
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
        roundCompleteCanDismiss = false
        tunnelDepth = 0
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
