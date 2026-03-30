import SwiftUI

@Observable
class GameState {
    let gridSize = GridPosition.gridSize

    var grid: [[PrismColor?]]
    var targetColor: PrismColor?
    var round: Int = 0
    var score: Int = 0
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: "prism_high_score") }
        set { UserDefaults.standard.set(newValue, forKey: "prism_high_score") }
    }
    var isGameOver: Bool = false
    var selectedPosition: GridPosition? = nil
    var isProcessing: Bool = false
    var showRoundComplete: Bool = false
    var matchedPosition: GridPosition? = nil
    var lastBlendPosition: GridPosition? = nil
    /// Positions currently animating a blend (both tiles shrink before result appears)
    var blendingPositions: (GridPosition, GridPosition)? = nil
    /// Tracks whether the just-completed round is a milestone (every 4th)
    var showMilestone: Bool = false

    // MARK: - Undo

    /// Snapshot of grid + score before the last blend (one undo per round)
    private var undoGrid: [[PrismColor?]]? = nil
    private var undoScore: Int? = nil
    var canUndo: Bool { undoGrid != nil }
    /// Whether the free undo has been used this round
    private var undoUsedThisRound: Bool = false

    // MARK: - Settings

    var showColorLabels: Bool {
        get { UserDefaults.standard.bool(forKey: "prism_show_labels") }
        set { UserDefaults.standard.set(newValue, forKey: "prism_show_labels") }
    }

    // MARK: - First-Round Hint

    /// Positions of the two tiles to highlight with a breathing glow on round 1
    var hintPositions: Set<GridPosition> = []
    /// Whether to show "Merge the colors" prompt
    var showMergeHint: Bool = false

    // MARK: - Difficulty Scaling

    var maxDepth: Int {
        if round <= 3 { return 1 }       // secondaries only
        if round <= 9 { return 2 }       // + depth-2 colors
        return 3                          // full 24-color wheel
    }

    var distractorCount: Int {
        if round <= 2 { return 0 }
        if round <= 5 { return 1 }
        if round <= 10 { return 2 }
        return 3
    }

    // MARK: - Init

    init() {
        grid = Array(repeating: Array(repeating: nil, count: GridPosition.gridSize),
                     count: GridPosition.gridSize)
        startNewRound()
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

    /// True if at least two tiles exist on the board (any two can blend).
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
        guard !isProcessing, !isGameOver, !showRoundComplete else { return }
        guard tile(at: pos) != nil else {
            selectedPosition = nil
            return
        }

        // Clear first-round hint as soon as player interacts
        if showMergeHint {
            hintPositions = []
            showMergeHint = false
        }

        if let sel = selectedPosition {
            if sel == pos {
                // Deselect
                selectedPosition = nil
            } else if tile(at: sel) != nil {
                // Blend any two tiles (no adjacency required)
                performBlend(sel, pos)
            } else {
                // Select different tile
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
        let result = PrismColor.mix(colorA, colorB)

        // Save undo snapshot (only if undo hasn't been used this round)
        if !undoUsedThisRound {
            undoGrid = grid.map { $0 }
            undoScore = score
        }

        // Phase 1: both tiles shrink (visual only — tiles still on grid during animation)
        blendingPositions = (posA, posB)

        Task {
            // Short pause for the shrink animation to play
            try? await Task.sleep(for: .milliseconds(150))

            // Phase 2: swap in result + play sound
            HapticManager.blend()
            SoundManager.shared.playBlendTone(for: result)

            grid[posA.row][posA.col] = result
            grid[posB.row][posB.col] = nil
            blendingPositions = nil
            lastBlendPosition = posA
            score += 10

            // Check if result matches target
            if let target = targetColor, result == target {
                matchedPosition = posA
                let roundBonus = round * 50
                score += roundBonus
                updateHighScore()

                try? await Task.sleep(for: .milliseconds(500))
                HapticManager.lineClear()

                let completedRound = round
                let isMilestone = completedRound % 4 == 0 && completedRound > 0
                if isMilestone {
                    SoundManager.shared.playMilestone()
                } else {
                    SoundManager.shared.playRoundComplete()
                }

                // Remove matched tile
                grid[posA.row][posA.col] = nil
                matchedPosition = nil
                lastBlendPosition = nil

                if isMilestone {
                    showMilestone = true
                    showRoundComplete = true
                    try? await Task.sleep(for: .milliseconds(2000))
                    showMilestone = false
                } else {
                    showRoundComplete = true
                    try? await Task.sleep(for: .milliseconds(1200))
                }

                showRoundComplete = false
                startNewRound()
                isProcessing = false
            } else {
                updateHighScore()
                try? await Task.sleep(for: .milliseconds(200))
                lastBlendPosition = nil
                checkGameOver()
                isProcessing = false
            }
        }
    }

    // MARK: - Undo Action

    func undoLastBlend() {
        guard let savedGrid = undoGrid, let savedScore = undoScore else { return }
        grid = savedGrid
        score = savedScore
        undoGrid = nil
        undoScore = nil
        undoUsedThisRound = true
        lastBlendPosition = nil
        selectedPosition = nil
    }

    // MARK: - Round Management

    func startNewRound() {
        round += 1
        selectedPosition = nil
        undoGrid = nil
        undoScore = nil
        undoUsedThisRound = false

        // Board persists! Only clear matched tile (already done in performBlend).
        // Check if the board already contains the target from a previous round's leftovers
        // — that's a freebie the player can tap.

        // Pick a target color at the current difficulty
        let candidates = PrismColor.targets(maxDepth: maxDepth)
        // Prefer targets not already on the board (don't give free wins)
        let boardColors = Set(grid.flatMap { $0 }.compactMap { $0 })
        let preferred = candidates.filter { !boardColors.contains($0) }
        targetColor = (preferred.isEmpty ? candidates : preferred).randomElement()

        guard let target = targetColor else { return }

        // Get primary ingredients (optimal decomposition)
        let ingredients = PrismColor.optimalIngredients[target.wheelIndex]
            ?? PrismColor.primaryIngredients(for: target)

        // Check if there's room to spawn ingredients
        let emptyCount = emptyPositions().count
        if emptyCount < ingredients.count {
            // Not enough room — game over (board is too cluttered)
            isGameOver = true
            HapticManager.gameOver()
            SoundManager.shared.playGameOver()
            return
        }

        // Spawn ingredients in a connected cluster
        let placed = spawnConnectedCluster(tiles: ingredients.shuffled())

        // Spawn distractors in random empty spots
        let numDistractors = min(distractorCount, emptyPositions().count)
        for _ in 0..<numDistractors {
            if let pos = emptyPositions().randomElement() {
                grid[pos.row][pos.col] = PrismColor.primaries.randomElement()!
            }
        }

        // First round: highlight ingredient tiles with a breathing glow
        if round == 1 {
            hintPositions = Set(placed)
            showMergeHint = true
        } else {
            hintPositions = []
            showMergeHint = false
        }
    }

    @discardableResult
    private func spawnConnectedCluster(tiles: [PrismColor]) -> [GridPosition] {
        guard !tiles.isEmpty else { return [] }
        let empty = emptyPositions()
        guard let start = empty.randomElement() else { return [] }

        var placed: [GridPosition] = []
        grid[start.row][start.col] = tiles[0]
        placed.append(start)

        for i in 1..<tiles.count {
            // Find empty cells adjacent to any already-placed tile
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
                // No adjacent empty cell — place anywhere (less ideal but game continues)
                grid[fallback.row][fallback.col] = tiles[i]
                placed.append(fallback)
            }
        }
        return placed
    }

    // MARK: - Game Over

    private func checkGameOver() {
        if !canStillWin() {
            isGameOver = true
            HapticManager.gameOver()
            SoundManager.shared.playGameOver()
        }
    }

    /// Check if the target can still be produced by some sequence of blends.
    /// Uses exhaustive search with memoization (capped at 50 000 nodes for safety).
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
        if nodes > 50_000 { return true }  // assume solvable if too complex
        if sorted.count < 2 { return false }
        if memo.contains(sorted) { return false }
        memo.insert(sorted)

        for i in 0..<sorted.count {
            for j in (i + 1)..<sorted.count {
                let result = PrismColor.mix(
                    PrismColor(wheelIndex: sorted[i]),
                    PrismColor(wheelIndex: sorted[j])
                ).wheelIndex

                // Found a blend that produces the target!
                if result == target { return true }

                // Try further blends from the resulting board
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
        startNewRound()
    }
}
