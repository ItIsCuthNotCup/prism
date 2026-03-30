import SwiftUI

struct GridView: View {
    var game: GameState
    let cellSize: CGFloat

    private let spacing: CGFloat = 5

    var body: some View {
        let totalSize = CGFloat(GridPosition.gridSize) * cellSize
            + CGFloat(GridPosition.gridSize - 1) * spacing

        ZStack {
            // Glass container with chromatic aberration

            // Chromatic aberration — offset red/blue border traces
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.red.opacity(0.06), lineWidth: 1.5)
                .frame(width: totalSize + 24, height: totalSize + 24)
                .offset(x: -1.5, y: -0.5)

            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.blue.opacity(0.06), lineWidth: 1.5)
                .frame(width: totalSize + 24, height: totalSize + 24)
                .offset(x: 1.5, y: 0.5)

            // Subtle green channel offset
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.green.opacity(0.03), lineWidth: 1)
                .frame(width: totalSize + 24, height: totalSize + 24)
                .offset(x: 0.5, y: -1)

            // Glass fill
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.45))
                .frame(width: totalSize + 24, height: totalSize + 24)

            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .frame(width: totalSize + 24, height: totalSize + 24)

            // Subtle inner highlight (top edge catch)
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .white.opacity(0.2), .white.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
                .frame(width: totalSize + 24, height: totalSize + 24)

            // Outer drop shadow for depth
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear)
                .frame(width: totalSize + 24, height: totalSize + 24)
                .shadow(color: .black.opacity(0.06), radius: 20, y: 8)

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
        .frame(width: totalSize + 24, height: totalSize + 24)
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
        let isHinted = game.hintPositions.contains(pos)
        let isPoison = game.poisonPositions.contains(pos)

        if let tileColor = game.tile(at: pos) {
            // Compute blend preview: small dot showing what this tile + selected tile would make
            let blendPreview: PrismColor? = {
                guard !isSelected, game.selectedPosition != nil else { return nil }
                return game.previewBlend(with: tileColor)
            }()

            TileView(
                color: tileColor,
                isSelected: isSelected,
                isMatched: isMatched,
                isBlendResult: isBlendResult,
                isBlending: isBlending,
                isHinted: isHinted,
                isPoison: isPoison,
                showLabel: game.showColorLabels,
                blendPreview: blendPreview
            )
            .id(tileColor.wheelIndex)
        } else {
            // Empty cell — subtle glass indent
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: 0xEFEFF2).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.white.opacity(0.4), lineWidth: 0.5)
                )
                .overlay(
                    // Inner shadow effect
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.black.opacity(0.03), .clear, .white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        }
    }

    // MARK: - Layout

    private func cellCenter(row: Int, col: Int, totalSize: CGFloat) -> CGPoint {
        let x = CGFloat(col) * (cellSize + spacing) + cellSize / 2 + 12
        let y = CGFloat(row) * (cellSize + spacing) + cellSize / 2 + 12
        return CGPoint(x: x, y: y)
    }
}
