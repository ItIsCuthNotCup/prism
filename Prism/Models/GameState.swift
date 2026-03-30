import SwiftUI

struct ClearedLine: Equatable {
    enum LineType { case row, column }
    let type: LineType
    let index: Int
    var positions: [GridPosition] {
        (0..<GridPosition.gridSize).map { i in
            switch type {
            case .row: return GridPosition(row: index, col: i)
            case .column: return GridPosition(row: i, col: index)
            }
        }
    }
}

struct ScorePopup: Identifiable {
    let id = UUID()
    let points: Int
    let position: GridPosition
}

@Observable
@MainActor
class GameState {
    private let size = GridPosition.gridSize

    var grid: [[TileColor?]]
    var nextTile: TileColor
    var score: Int = 0
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: "prism_high_score") }
        set { UserDefaults.standard.set(newValue, forKey: "prism_high_score") }
    }
    var isGameOver: Bool = false
    var cascadeMultiplier: Int = 1

    // Animation state
    var clearingPositions: Set<GridPosition> = []
    var fallingTiles: [GridPosition: Int] = [:] // position -> rows to fall
    var blendingBorder: CellBorder? = nil
    var blendResultPosition: GridPosition? = nil
    var blendResultColor: TileColor? = nil
    var placedPosition: GridPosition? = nil
    var spawnedPosition: GridPosition? = nil
    var scorePopups: [ScorePopup] = []
    var isProcessing: Bool = false

    init() {
        grid = Array(repeating: Array(repeating: nil, count: GridPosition.gridSize), count: GridPosition.gridSize)
        nextTile = TileColor.randomPrimary()
    }

    // MARK: - Queries

    func tile(at pos: GridPosition) -> TileColor? {
        guard pos.row >= 0, pos.row < size, pos.col >= 0, pos.col < size else { return nil }
        return grid[pos.row][pos.col]
    }

    func isEmpty(at pos: GridPosition) -> Bool {
        tile(at: pos) == nil
    }

    func emptyPositions() -> [GridPosition] {
        var result: [GridPosition] = []
        for r in 0..<size {
            for c in 0..<size {
                if grid[r][c] == nil {
                    result.append(GridPosition(row: r, col: c))
                }
            }
        }
        return result
    }

    func availableBlends() -> [CellBorder: TileColor] {
        var blends: [CellBorder: TileColor] = [:]
        for r in 0..<size {
            for c in 0..<size {
                let pos = GridPosition(row: r, col: c)
                guard let tileA = tile(at: pos), tileA.isPrimary else { continue }
                // Check right neighbor
                if c + 1 < size {
                    let right = GridPosition(row: r, col: c + 1)
                    if let tileB = tile(at: right), let result = TileColor.blend(tileA, tileB) {
                        blends[CellBorder(pos, right)] = result
                    }
                }
                // Check bottom neighbor
                if r + 1 < size {
                    let below = GridPosition(row: r + 1, col: c)
                    if let tileB = tile(at: below), let result = TileColor.blend(tileA, tileB) {
                        blends[CellBorder(pos, below)] = result
                    }
                }
            }
        }
        return blends
    }

    var isGridFull: Bool {
        emptyPositions().isEmpty
    }

    // MARK: - Actions

    func placeTile(at pos: GridPosition) {
        guard isEmpty(at: pos), !isProcessing else { return }
        isProcessing = true
        placedPosition = pos

        grid[pos.row][pos.col] = nextTile
        nextTile = TileColor.randomPrimary()

        Task {
            try? await Task.sleep(for: .milliseconds(350))
            placedPosition = nil

            let didClear = await resolveClears()

            if !didClear {
                spawnRandomTile()
            }

            checkGameOver()
            isProcessing = false
        }
    }

    func blendTiles(border: CellBorder) {
        guard !isProcessing else { return }
        let a = border.posA
        let b = border.posB
        guard let tileA = tile(at: a), let tileB = tile(at: b),
              let result = TileColor.blend(tileA, tileB) else { return }

        isProcessing = true
        blendingBorder = border
        blendResultColor = result
        blendResultPosition = a

        score += 10
        updateHighScore()

        Task {
            // Wait for blend animation
            try? await Task.sleep(for: .milliseconds(300))

            grid[a.row][a.col] = result
            grid[b.row][b.col] = nil

            blendingBorder = nil
            blendResultPosition = nil
            blendResultColor = nil

            try? await Task.sleep(for: .milliseconds(100))

            let _ = await resolveClears()
            // No spawn after blend — blending is a free action
            checkGameOver()
            isProcessing = false
        }
    }

    // MARK: - Clear & Gravity

    func findClears() -> [ClearedLine] {
        var clears: [ClearedLine] = []
        for r in 0..<size {
            if let first = grid[r][0] {
                if (1..<size).allSatisfy({ grid[r][$0] == first }) {
                    clears.append(ClearedLine(type: .row, index: r))
                }
            }
        }
        for c in 0..<size {
            if let first = grid[0][c] {
                if (1..<size).allSatisfy({ grid[$0][c] == first }) {
                    clears.append(ClearedLine(type: .column, index: c))
                }
            }
        }
        return clears
    }

    @discardableResult
    func resolveClears() async -> Bool {
        cascadeMultiplier = 1
        var didClear = false

        while true {
            let clears = findClears()
            if clears.isEmpty { break }
            didClear = true

            var positionsToRemove = Set<GridPosition>()
            for line in clears {
                for pos in line.positions {
                    positionsToRemove.insert(pos)
                }
            }

            let points = clears.count * 100 * cascadeMultiplier
            score += points
            updateHighScore()

            // Show score popup at first cleared position
            if let first = positionsToRemove.first {
                scorePopups.append(ScorePopup(points: points, position: first))
            }

            // Haptic feedback
            if cascadeMultiplier > 1 {
                HapticManager.cascade()
            } else {
                HapticManager.lineClear()
            }

            clearingPositions = positionsToRemove

            // Wait for clear animation
            try? await Task.sleep(for: .milliseconds(350))

            // Remove cleared tiles
            for pos in positionsToRemove {
                grid[pos.row][pos.col] = nil
            }
            clearingPositions = []

            // Apply gravity
            applyGravity()

            // Wait for gravity animation
            try? await Task.sleep(for: .milliseconds(300))
            fallingTiles = [:]

            cascadeMultiplier += 1

            // Brief cascade pause
            try? await Task.sleep(for: .milliseconds(300))
        }

        if !didClear {
            clearingPositions = []
        }

        // Clean up old popups
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            scorePopups.removeAll()
        }

        return didClear
    }

    func applyGravity() {
        fallingTiles = [:]
        for c in 0..<size {
            var writeRow = size - 1
            for r in stride(from: size - 1, through: 0, by: -1) {
                if grid[r][c] != nil {
                    if r != writeRow {
                        grid[writeRow][c] = grid[r][c]
                        grid[r][c] = nil
                        let dest = GridPosition(row: writeRow, col: c)
                        fallingTiles[dest] = writeRow - r
                    }
                    writeRow -= 1
                }
            }
        }
    }

    func spawnRandomTile() {
        let empty = emptyPositions()
        guard !empty.isEmpty else { return }
        let pos = empty.randomElement()!
        grid[pos.row][pos.col] = TileColor.randomPrimary()
        spawnedPosition = pos

        Task {
            try? await Task.sleep(for: .milliseconds(350))
            spawnedPosition = nil
        }
    }

    func checkGameOver() {
        if isGridFull && availableBlends().isEmpty {
            isGameOver = true
            HapticManager.gameOver()
        }
    }

    func updateHighScore() {
        if score > highScore {
            highScore = score
        }
    }

    func newGame() {
        grid = Array(repeating: Array(repeating: nil, count: size), count: size)
        nextTile = TileColor.randomPrimary()
        score = 0
        isGameOver = false
        cascadeMultiplier = 1
        clearingPositions = []
        fallingTiles = [:]
        blendingBorder = nil
        blendResultPosition = nil
        blendResultColor = nil
        placedPosition = nil
        spawnedPosition = nil
        scorePopups = []
        isProcessing = false
    }
}
