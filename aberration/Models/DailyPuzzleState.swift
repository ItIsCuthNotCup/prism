import SwiftUI

// MARK: - Seeded Random Number Generator

/// Deterministic RNG seeded by day — same puzzle for everyone on the same date.
struct DailyRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    init(date: Date = Date()) {
        let cal = Calendar(identifier: .gregorian)
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        let raw = UInt64(y) * 10000 + UInt64(m) * 100 + UInt64(d)
        state = raw ^ 0x6C62_7263_6173_7464
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Attempt Record

/// One failed or successful attempt: the 3 tiles picked and what they produced.
struct DailyAttempt: Identifiable {
    let id = UUID()
    let tile1: PrismColor
    let tile2: PrismColor
    let tile3: PrismColor
    let intermediate: PrismColor   // mix(tile1, tile2)
    let result: PrismColor         // mix(intermediate, tile3)
    let isCorrect: Bool
}

// MARK: - Daily Puzzle State (Formula Mechanic)

@Observable
class DailyPuzzleState {
    /// Set to true during development to get a fresh random puzzle each launch.
    static let testMode = true

    // Grid
    let gridSize = 5
    var grid: [[PrismColor?]]

    // Puzzle definition
    var targetColor: PrismColor
    /// The 3 tiles that solve it: mix(mix(sol[0], sol[1]), sol[2]) == target
    var solutionTiles: [PrismColor]

    // Selection state — pick tiles one at a time
    var picks: [PrismColor] = []           // tiles picked so far this attempt (0-3)
    var pickPositions: [GridPosition] = []  // grid positions of picks

    /// After picking 2, this is mix(pick[0], pick[1])
    var intermediate: PrismColor? {
        guard picks.count >= 2 else { return nil }
        return PrismColor.mix(picks[0], picks[1])
    }

    // Attempts
    var attempts: [DailyAttempt] = []
    let maxAttempts = 5
    var isSolved: Bool = false
    var isFailed: Bool = false

    // Toast
    var toastText: String? = nil

    // Persistence
    var todayKey: String

    /// Puzzle number for share text.
    var puzzleNumber: Int {
        let cal = Calendar(identifier: .gregorian)
        let epoch = cal.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let today = cal.startOfDay(for: Date())
        return (cal.dateComponents([.day], from: epoch, to: today).day ?? 0) + 1
    }

    var attemptsRemaining: Int { maxAttempts - attempts.count }

    init(date: Date = Date()) {
        let cal = Calendar(identifier: .gregorian)
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        todayKey = String(format: "%04d-%02d-%02d", y, m, d)

        grid = Array(repeating: Array(repeating: nil, count: 5), count: 5)
        targetColor = PrismColor.byIndex(8)
        solutionTiles = []

        if Self.testMode {
            generateRandom()
        } else {
            generate(date: date)

            // Restore saved state
            if let saved = UserDefaults.standard.dictionary(forKey: "daily_\(todayKey)") {
                isSolved = saved["solved"] as? Bool ?? false
                isFailed = saved["failed"] as? Bool ?? false
                let usedAttempts = saved["attemptsUsed"] as? Int ?? 0
                // We don't restore full attempt history from persistence,
                // just the end state. The overlay shows solved/failed.
                if isSolved || isFailed {
                    // Create placeholder attempts so attemptsRemaining is correct
                    for _ in 0..<usedAttempts {
                        attempts.append(DailyAttempt(
                            tile1: targetColor, tile2: targetColor, tile3: targetColor,
                            intermediate: targetColor, result: targetColor, isCorrect: false
                        ))
                    }
                }
            }
        }
    }

    // MARK: - Puzzle Generation

    /// Find a valid target + 3 solution tiles where mix(mix(A,B), C) == target.
    private func generateRandom() {
        // Pick depth-2 targets: these decompose as mix(parent1, parent2),
        // and one parent decomposes further → 3 tiles total.
        let depth2Targets = PrismColor.allColors.filter { $0.depth == 2 }
        let target = depth2Targets.randomElement()!
        targetColor = target
        solutionTiles = findSolution(for: target)

        var positions = allPositions()
        positions.shuffle()
        fillGrid(positions: positions)
    }

    private func generate(date: Date) {
        var rng = DailyRNG(date: date)

        let depth2Targets = PrismColor.allColors.filter { $0.depth == 2 }
        let target = depth2Targets[Int.random(in: 0..<depth2Targets.count, using: &rng)]
        targetColor = target
        solutionTiles = findSolution(for: target)

        var positions = allPositions()
        positions.shuffle(using: &rng)

        var distractorPool = PrismColor.allColors.filter {
            !Set(solutionTiles.map(\.wheelIndex)).contains($0.wheelIndex)
        }
        distractorPool.shuffle(using: &rng)
        fillGrid(positions: positions, distractors: distractorPool)
    }

    /// Find 3 tiles [A, B, C] such that mix(mix(A, B), C) == target.
    /// Uses the directPair decomposition: target = mix(P1, P2), then decompose P1 or P2.
    private func findSolution(for target: PrismColor) -> [PrismColor] {
        guard let (parentA, parentB) = PrismColor.directPair[target.wheelIndex] else {
            return []
        }

        // Try decomposing parentA → (a1, a2), solution = [a1, a2, parentB]
        if let (a1, a2) = PrismColor.directPair[parentA.wheelIndex] {
            let checkIntermediate = PrismColor.mix(a1, a2)
            let checkResult = PrismColor.mix(checkIntermediate, parentB)
            if checkResult.wheelIndex == target.wheelIndex {
                return [a1, a2, parentB]
            }
        }

        // Try decomposing parentB → (b1, b2), solution = [b1, b2, parentA]
        if let (b1, b2) = PrismColor.directPair[parentB.wheelIndex] {
            let checkIntermediate = PrismColor.mix(b1, b2)
            let checkResult = PrismColor.mix(checkIntermediate, parentA)
            if checkResult.wheelIndex == target.wheelIndex {
                return [b1, b2, parentA]
            }
        }

        // Fallback: just use the two direct parents + a primary that gets there
        return [parentA, parentB, parentA]
    }

    private func allPositions() -> [GridPosition] {
        var p: [GridPosition] = []
        for r in 0..<gridSize { for c in 0..<gridSize { p.append(GridPosition(row: r, col: c)) } }
        return p
    }

    private func fillGrid(positions: [GridPosition], distractors: [PrismColor]? = nil) {
        var newGrid: [[PrismColor?]] = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)

        // Place solution tiles
        for (i, tile) in solutionTiles.enumerated() {
            let pos = positions[i]
            newGrid[pos.row][pos.col] = tile
        }

        // Fill remaining with distractors
        var pool = distractors ?? {
            var p = PrismColor.allColors.filter {
                !Set(solutionTiles.map(\.wheelIndex)).contains($0.wheelIndex)
            }
            p.shuffle()
            return p
        }()

        for i in solutionTiles.count..<positions.count {
            let pos = positions[i]
            newGrid[pos.row][pos.col] = pool[(i - solutionTiles.count) % pool.count]
        }
        grid = newGrid
    }

    // MARK: - Tile Selection (Formula Mechanic)

    func selectTile(at pos: GridPosition) {
        guard !isSolved, !isFailed else { return }
        guard grid[pos.row][pos.col] != nil else { return }

        // If already picked this position, deselect it (only if it's the last pick)
        if let lastIdx = pickPositions.lastIndex(of: pos), lastIdx == pickPositions.count - 1 {
            picks.removeLast()
            pickPositions.removeLast()
            HapticManager.blend()
            return
        }

        // Don't allow selecting already-picked positions
        if pickPositions.contains(pos) { return }

        // Can't pick more than 3
        guard picks.count < 3 else { return }

        let tileColor = grid[pos.row][pos.col]!
        picks.append(tileColor)
        pickPositions.append(pos)
        HapticManager.blend()

        // If we now have 2, show the intermediate (no action needed — computed property handles it)
        // Play blend sound on pick 2 to emphasize the mix
        if picks.count == 2 {
            SoundManager.shared.playBlendTone(for: PrismColor.mix(picks[0], picks[1]))
        }

        // If we now have 3, auto-check after a brief moment
        if picks.count == 3 {
            checkAttempt()
        }
    }

    private func checkAttempt() {
        let t1 = picks[0]
        let t2 = picks[1]
        let t3 = picks[2]
        let inter = PrismColor.mix(t1, t2)
        let result = PrismColor.mix(inter, t3)
        let correct = result.wheelIndex == targetColor.wheelIndex

        let attempt = DailyAttempt(
            tile1: t1, tile2: t2, tile3: t3,
            intermediate: inter, result: result, isCorrect: correct
        )
        attempts.append(attempt)

        if correct {
            isSolved = true
            HapticManager.lineClear()
            SoundManager.shared.playMilestone()
            saveTodayResult()
        } else {
            HapticManager.gameOver()

            if attempts.count >= maxAttempts {
                isFailed = true
                SoundManager.shared.playGameOver()
                saveTodayResult()
            } else {
                showToast("You made \(result.name) — not \(targetColor.name)")
            }
        }

        // Clear picks for next attempt
        picks = []
        pickPositions = []
    }

    /// Clear current picks without submitting (reset button)
    func clearPicks() {
        picks = []
        pickPositions = []
    }

    // MARK: - Persistence

    private func saveTodayResult() {
        guard !Self.testMode else { return }
        let data: [String: Any] = [
            "solved": isSolved,
            "failed": isFailed,
            "attemptsUsed": attempts.count
        ]
        UserDefaults.standard.set(data, forKey: "daily_\(todayKey)")
    }

    // MARK: - Share

    var shareText: String {
        // Emoji per attempt: 🟩 = correct, 🟨 = close (within 4 steps), 🟥 = far
        var emojis: [String] = []
        for attempt in attempts {
            if attempt.isCorrect {
                emojis.append("🟩")
            } else {
                let dist = wheelDistance(attempt.result.wheelIndex, targetColor.wheelIndex)
                if dist <= 4 {
                    emojis.append("🟨")
                } else {
                    emojis.append("🟥")
                }
            }
        }

        let emojiLine = emojis.joined()

        if isSolved {
            return "Stillhue \u{1F3A8} #\(puzzleNumber)\n\(emojiLine) — \(attempts.count)/\(maxAttempts)"
        } else {
            return "Stillhue \u{1F3A8} #\(puzzleNumber)\n\(emojiLine) — X/\(maxAttempts)"
        }
    }

    private func wheelDistance(_ a: Int, _ b: Int) -> Int {
        let d = abs(a - b)
        return min(d, 48 - d)
    }

    func showToast(_ text: String) {
        toastText = text
    }

    var hasPlayedToday: Bool {
        guard !Self.testMode else { return false }
        return isSolved || isFailed
    }

    var scoreTier: String {
        switch attempts.count {
        case 1: return "Genius"
        case 2: return "Brilliant"
        case 3: return "Great"
        case 4: return "Good"
        case 5: return "Close one"
        default: return ""
        }
    }
}
