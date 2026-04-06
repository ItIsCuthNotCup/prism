import Foundation

struct GridPosition: Hashable, Equatable, Sendable {
    let row: Int
    let col: Int

    func isAdjacent(to other: GridPosition) -> Bool {
        let dr = abs(row - other.row)
        let dc = abs(col - other.col)
        return (dr == 1 && dc == 0) || (dr == 0 && dc == 1)
    }

    static let gridSize = 5
}
