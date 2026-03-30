import SwiftUI

struct GridView: View {
    var game: GameState
    let cellSize: CGFloat

    private let spacing: CGFloat = 4
    private let blendTapWidth: CGFloat = 24

    var body: some View {
        let blends = game.isProcessing ? [:] : game.availableBlends()
        let totalSize = CGFloat(GridPosition.gridSize) * cellSize + CGFloat(GridPosition.gridSize - 1) * spacing

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
                            guard !game.isProcessing, game.isEmpty(at: pos) else { return }
                            HapticManager.tilePlaced()
                            game.placeTile(at: pos)
                        }
                }
            }

            // Blend glow indicators and tap targets
            ForEach(Array(blends.keys), id: \.self) { border in
                if let resultColor = blends[border] {
                    blendIndicator(border: border, resultColor: resultColor, totalSize: totalSize)
                }
            }

            // Score popups
            ForEach(game.scorePopups) { popup in
                scorePopupView(popup: popup, totalSize: totalSize)
            }
        }
        .frame(width: totalSize + 16, height: totalSize + 16)
    }

    // MARK: - Cell

    @ViewBuilder
    private func cellView(at pos: GridPosition) -> some View {
        let isClearing = game.clearingPositions.contains(pos)
        let isBlendSource = game.blendingBorder != nil &&
            (game.blendingBorder!.posA == pos || game.blendingBorder!.posB == pos)
        let isBlendResult = game.blendResultPosition == pos

        if let tileColor = game.tile(at: pos) {
            if isClearing {
                // Flash white then scale down
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .scaleEffect(1.0)
                    .opacity(0.9)
                    .animation(.easeOut(duration: 0.15), value: isClearing)
            } else if isBlendSource {
                // Blend source: shrink toward midpoint
                TileView(color: tileColor, appearAnimation: false)
                    .scaleEffect(0.3)
                    .opacity(0.3)
                    .animation(.easeInOut(duration: 0.25), value: game.blendingBorder != nil)
            } else if isBlendResult {
                // Blend result: bloom in
                if let resultColor = game.blendResultColor {
                    TileView(color: resultColor, appearAnimation: true)
                } else {
                    TileView(color: tileColor, appearAnimation: false)
                }
            } else {
                let shouldAnimate = pos == game.placedPosition || pos == game.spawnedPosition
                TileView(color: tileColor, appearAnimation: shouldAnimate)
                    .offset(y: fallingOffset(for: pos))
                    .animation(.easeIn(duration: 0.15), value: game.fallingTiles.isEmpty)
            }
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

    private func fallingOffset(for pos: GridPosition) -> CGFloat {
        guard let rows = game.fallingTiles[pos], rows > 0 else { return 0 }
        return -CGFloat(rows) * (cellSize + spacing)
    }

    // MARK: - Blend Indicator

    private func blendIndicator(border: CellBorder, resultColor: TileColor, totalSize: CGFloat) -> some View {
        let centerA = cellCenter(row: border.posA.row, col: border.posA.col, totalSize: totalSize)
        let centerB = cellCenter(row: border.posB.row, col: border.posB.col, totalSize: totalSize)
        let midX = (centerA.x + centerB.x) / 2
        let midY = (centerA.y + centerB.y) / 2

        let isHorizontal = border.isHorizontal
        let tapWidth: CGFloat = blendTapWidth
        let tapHeight: CGFloat = cellSize * 0.7

        return BlendGlowView(color: resultColor.color)
            .frame(
                width: isHorizontal ? tapWidth : tapHeight,
                height: isHorizontal ? tapHeight : tapWidth
            )
            .position(x: midX, y: midY)
            .onTapGesture {
                guard !game.isProcessing else { return }
                HapticManager.blend()
                game.blendTiles(border: border)
            }
    }

    // MARK: - Score Popup

    private func scorePopupView(popup: ScorePopup, totalSize: CGFloat) -> some View {
        let center = cellCenter(row: popup.position.row, col: popup.position.col, totalSize: totalSize)
        return Text("+\(popup.points)")
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 4)
            .position(x: center.x, y: center.y - 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeOut(duration: 0.8), value: game.scorePopups.count)
    }

    // MARK: - Layout

    private func cellCenter(row: Int, col: Int, totalSize: CGFloat) -> CGPoint {
        let offset = (totalSize - (CGFloat(GridPosition.gridSize) * cellSize + CGFloat(GridPosition.gridSize - 1) * spacing)) / 2
        let x = offset + CGFloat(col) * (cellSize + spacing) + cellSize / 2 + 8
        let y = offset + CGFloat(row) * (cellSize + spacing) + cellSize / 2 + 8
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Blend Glow

struct BlendGlowView: View {
    let color: Color
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color.opacity(pulse ? 0.6 : 0.3))
            .shadow(color: color.opacity(0.5), radius: pulse ? 8 : 4)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}
