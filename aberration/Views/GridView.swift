import SwiftUI

struct GridView: View {
    var game: GameState
    let cellSize: CGFloat

    private let spacing: CGFloat = 4

    var body: some View {
        let totalSize = CGFloat(GridPosition.gridSize) * cellSize
            + CGFloat(GridPosition.gridSize - 1) * spacing

        ZStack {
            // Grid background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: 0x1D1E2C))
                .frame(width: totalSize + 16, height: totalSize + 16)

            // Cells
            ForEach(0..<GridPosition.gridSize, id: \.self) { row in
                ForEach(0..<GridPosition.gridSize, id: \.self) { col in
                    let pos = GridPosition(row: row, col: col)
                    cellView(at: pos)
                        .frame(width: cellSize, height: cellSize)
                        .position(cellCenter(row: row, col: col, totalSize: totalSize))
                        .onTapGesture {
                            game.selectTile(at: pos)
                        }
                }
            }
        }
        .frame(width: totalSize + 16, height: totalSize + 16)
    }

    // MARK: - Cell

    @ViewBuilder
    private func cellView(at pos: GridPosition) -> some View {
        let isSelected = game.selectedPosition == pos
        let isMatched = game.matchedPosition == pos
        let isBlendResult = game.lastBlendPosition == pos
        let isBlending: Bool = {
            guard let (a, b) = game.blendingPositions else { return false }
            return pos == a || pos == b
        }()

        if let tileColor = game.tile(at: pos) {
            TileView(
                color: tileColor,
                isSelected: isSelected,
                isMatched: isMatched,
                isBlendResult: isBlendResult,
                isBlending: isBlending
            )
            .id(tileColor.wheelIndex)
        } else {
            // Empty cell
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: 0x2B2D42))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(hex: 0x3D405B), lineWidth: 1)
                )
        }
    }

    // MARK: - Layout

    private func cellCenter(row: Int, col: Int, totalSize: CGFloat) -> CGPoint {
        let x = CGFloat(col) * (cellSize + spacing) + cellSize / 2 + 8
        let y = CGFloat(row) * (cellSize + spacing) + cellSize / 2 + 8
        return CGPoint(x: x, y: y)
    }
}
