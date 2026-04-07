import SwiftUI

struct GridView: View {
    var game: GameState
    let cellSize: CGFloat
    private var theme: AppTheme { AppTheme.shared }

    private let spacing: CGFloat = 5
    private let inset: CGFloat = 6

    /// Tracks which cell indices have completed their entry animation
    @State private var enteredCells: Set<Int> = []
    /// Last observed roundEntryTrigger — detects new rounds
    @State private var lastEntryTrigger: Int = -1

    var body: some View {
        let columns = Array(
            repeating: GridItem(.fixed(cellSize), spacing: spacing),
            count: GridPosition.gridSize
        )

        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(0..<GridPosition.gridSize * GridPosition.gridSize, id: \.self) { index in
                let row = index / GridPosition.gridSize
                let col = index % GridPosition.gridSize
                let pos = GridPosition(row: row, col: col)

                cellView(at: pos)
                    .frame(width: cellSize, height: cellSize)
                    .scaleEffect(enteredCells.contains(index) ? 1.0 : 0.01)
                    .opacity(enteredCells.contains(index) ? 1.0 : 0.0)
                    .onTapGesture {
                        game.selectTile(at: pos)
                    }
            }
        }
        .padding(inset)
        .onChange(of: game.roundEntryTrigger) { _, newValue in
            // New round: reset all cells, then stagger them in
            enteredCells = []
            let total = GridPosition.gridSize * GridPosition.gridSize
            for i in 0..<total {
                let delay = Double(i) * 0.008  // 8ms stagger per cell — fast wave
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                        _ = enteredCells.insert(i)
                    }
                }
            }
        }
        .onAppear {
            // Initial load: show all cells immediately (no cascade on first appear)
            let total = GridPosition.gridSize * GridPosition.gridSize
            enteredCells = Set(0..<total)
            lastEntryTrigger = game.roundEntryTrigger
        }
    }

    // MARK: - Glass Container

    private var glassContainer: some View {
        ZStack {
            // Chromatic aberration — offset red/blue border traces
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.red.opacity(0.06), lineWidth: 1.5)
                .offset(x: -1.5, y: -0.5)

            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.blue.opacity(0.06), lineWidth: 1.5)
                .offset(x: 1.5, y: 0.5)

            // Subtle green channel offset
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.green.opacity(0.03), lineWidth: 1)
                .offset(x: 0.5, y: -1)

            // Glass fill
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.45))

            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)

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
        }
        .shadow(color: .black.opacity(0.06), radius: 20, y: 8)
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
        let isPopping = game.poppingPositions.contains(pos)
        let isHinted = game.hintPositions.contains(pos)
        let isPoison = game.poisonPositions.contains(pos)
        let isGolden = game.goldenPositions.contains(pos)
        // Proximity hints removed — they were visually noisy

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
                isPopping: isPopping,
                isHinted: isHinted,
                isPoison: isPoison,
                showLabel: game.showColorLabels,
                blendPreview: blendPreview
            )
            .background {
                // Colored bloom glow behind filled tiles (dark mode only)
                if theme.tileGlowOpacity > 0 {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tileColor.color.opacity(theme.tileGlowOpacity))
                        .blur(radius: theme.tileGlowRadius)
                        .scaleEffect(1.15)
                }
                if isGolden {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: 0xFFD700).opacity(0.5))
                        .blur(radius: 8)
                        .scaleEffect(1.25)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isGolden {
                    Text("✦")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: 0xFFD700))
                        .shadow(color: Color(hex: 0xFFD700), radius: 3)
                        .offset(x: 2, y: -2)
                }
            }
        } else {
            // Empty cell — subtle depth with inner glow in dark mode
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [theme.emptyCellTop, theme.emptyCellBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Faint inner glow — makes cells feel like receptacles, not holes
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    theme.emptyCellInnerGlow.opacity(theme.emptyCellInnerGlowOpacity * 2),
                                    theme.emptyCellInnerGlow.opacity(theme.emptyCellInnerGlowOpacity)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(theme.emptyCellBorder.opacity(0.5), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(theme.emptyCellShadowOpacity), radius: 2, y: 1)
        }
    }

    // MARK: - Proximity Hint Badge

    private func proximityBadge(_ hint: GameState.ProximityHint) -> some View {
        let color: Color = switch hint {
            case .hot:   Color(hex: 0xFF6B35)
            case .warm:  Color(hex: 0xFFB800)
            case .close: Color(hex: 0x66AACC)
        }

        return Text(hint.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 4, y: 2)
            )
            .allowsHitTesting(false)
    }
}
