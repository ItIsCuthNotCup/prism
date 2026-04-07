//
//  MixingLaneView.swift
//  aberration
//
//  Horizontal scrollable factory line of mixing tiles.
//  Shows blend history and active lava lamp animations.
//  Auto-scrolls to keep the newest tile centered.
//  Always shows exactly 5 tile slots for visual symmetry.
//

import SwiftUI

struct MixingLaneView: View {
    let lane: MixingLaneState
    let cellSize: CGFloat
    let gridWidth: CGFloat
    private var theme: AppTheme { AppTheme.shared }

    private let tileSpacing: CGFloat = 6
    private let verticalPadding: CGFloat = 10

    /// Always show exactly 5 tile slots total (filled + empties)
    private let totalSlots = 5

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: tileSpacing) {
                        if lane.tiles.count <= totalSlots {
                            // Show exactly 5 slots — fill with tiles, rest are empties
                            ForEach(0..<totalSlots, id: \.self) { i in
                                if i < lane.tiles.count {
                                    let tile = lane.tiles[i]
                                    MixingTileView(tile: tile, size: cellSize)
                                        .id(tile.id)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.6).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                } else {
                                    emptyGlass
                                        .id("empty_\(i)")
                                }
                            }
                        } else {
                            // More than 5 tiles — show all + 2 trailing empties
                            ForEach(lane.tiles) { tile in
                                MixingTileView(tile: tile, size: cellSize)
                                    .id(tile.id)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                            ForEach(0..<2, id: \.self) { i in
                                emptyGlass
                                    .id("trail_\(lane.tiles.count)_\(i)")
                            }
                        }
                    }
                    .padding(.horizontal, horizontalInset)
                    .padding(.vertical, verticalPadding)
                }
                .onChange(of: lane.tiles.count) { _, _ in
                    if let lastID = lane.tiles.last?.id {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            proxy.scrollTo(lastID, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(height: cellSize + verticalPadding * 2)
    }

    // MARK: - Helpers

    private var horizontalInset: CGFloat {
        // Center the 5 tiles within the grid width
        let totalTileWidth = CGFloat(totalSlots) * cellSize + CGFloat(totalSlots - 1) * tileSpacing
        let inset = max((gridWidth - totalTileWidth) / 2, 8)
        return inset
    }

    private var emptyGlass: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.mixGlassTop.opacity(0.6),
                            theme.mixGlassBottom.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(theme.isDark ? 0.15 : 0.5), Color.white.opacity(theme.isDark ? 0.05 : 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )

            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(theme.mixGlassDash.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .frame(width: cellSize, height: cellSize)
    }
}
