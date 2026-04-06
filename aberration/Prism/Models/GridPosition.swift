import Foundation

struct GridPosition: Hashable, Equatable {
    let row: Int
    let col: Int

    func isAdjacent(to other: GridPosition) -> Bool {
        let dr = abs(row - other.row)
        let dc = abs(col - other.col)
        return (dr == 1 && dc == 0) || (dr == 0 && dc == 1)
    }

    static let gridSize = 5
}

struct CellBorder: Hashable, Equatable {
    let posA: GridPosition
    let posB: GridPosition

    init(_ a: GridPosition, _ b: GridPosition) {
        // Normalize order so (a,b) and (b,a) hash the same
        if a.row < b.row || (a.row == b.row && a.col < b.col) {
            posA = a
            posB = b
        } else {
            posA = b
            posB = a
        }
    }

    var isHorizontal: Bool {
        posA.row == posB.row
    }
}
