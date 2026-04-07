//
//  MixingLaneState.swift
//  aberration
//
//  Manages the mixing lane — a factory-line queue of tiles that shows
//  blend animations and history beneath the game grid.
//

import SwiftUI

/// A single tile in the mixing lane.
struct MixingTile: Identifiable {
    let id = UUID()
    let colorA: Color
    let colorB: Color
    let resultColor: Color

    /// 0 → empty, 1 → fully settled to result color.
    var progress: Double = 0

    /// When the fill animation started (for TimelineView)
    var startDate: Date? = nil

    /// Total swirl duration in seconds — varies per tile for visual variety
    let swirlDuration: Double

    /// Whether this tile has fully settled
    var isComplete: Bool { progress >= 1.0 }

    init(colorA: Color, colorB: Color, resultColor: Color) {
        self.colorA = colorA
        self.colorB = colorB
        self.resultColor = resultColor
        // ~50 seconds — long enough to fully dissolve with no visible transition
        self.swirlDuration = 45.0 + Double.random(in: 0...10.0)
    }
}

@Observable
class MixingLaneState {
    /// All tiles, oldest first. Newest is last.
    var tiles: [MixingTile] = []

    /// ID of the tile currently being filled (newest)
    var activeTileID: UUID? { tiles.last?.id }

    /// Add a new blend to the lane. Returns the tile ID for scrolling.
    @discardableResult
    func addBlend(colorA: Color, colorB: Color, resultColor: Color) -> UUID {
        var tile = MixingTile(colorA: colorA, colorB: colorB, resultColor: resultColor)
        tile.startDate = Date()
        tiles.append(tile)
        return tile.id
    }

    /// Update progress for all active (incomplete) tiles based on elapsed time.
    func updateProgress() {
        for i in tiles.indices {
            guard let start = tiles[i].startDate, !tiles[i].isComplete else { continue }
            let elapsed = Date().timeIntervalSince(start)
            tiles[i].progress = min(elapsed / tiles[i].swirlDuration, 1.0)
        }
    }

    /// Clear all tiles (new game)
    func reset() {
        tiles.removeAll()
    }
}
