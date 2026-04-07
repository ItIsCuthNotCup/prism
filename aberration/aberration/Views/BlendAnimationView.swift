//
//  BlendAnimationView.swift
//  aberration
//
//  Lift → Merge → Drop blend animation.
//  Both tiles lift up, slide together and merge colors,
//  then the result drops back to its grid position.
//

import SwiftUI

/// Describes an in-flight merge animation.
struct MergeAnimation: Equatable, Sendable {
    let posA: GridPosition       // result lands here
    let posB: GridPosition       // second tile (gets consumed)
    let colorA: Color
    let colorB: Color
    let resultColor: Color
    let cellSize: CGFloat
    let spacing: CGFloat
    let gridInset: CGFloat

    /// Screen-space center for a grid position (relative to the grid's top-left).
    func center(for pos: GridPosition) -> CGPoint {
        let x = gridInset + CGFloat(pos.col) * (cellSize + spacing) + cellSize / 2
        let y = gridInset + CGFloat(pos.row) * (cellSize + spacing) + cellSize / 2
        return CGPoint(x: x, y: y)
    }
}

struct BlendAnimationView: View {
    let merge: MergeAnimation

    // Animation phases
    @State private var lifted = false       // Phase 1: tiles lift up
    @State private var merged = false       // Phase 2: tiles slide together + color merge
    @State private var dropped = false      // Phase 3: result drops back
    @State private var settled = false      // Phase 4: overshoot settles

    private let tileRadius: CGFloat = 10

    var body: some View {
        let originA = merge.center(for: merge.posA)
        let originB = merge.center(for: merge.posB)

        // Mixing zone: midpoint between the two tiles, shifted upward
        let midX = (originA.x + originB.x) / 2
        let liftAmount = merge.cellSize * 1.8  // how far up tiles float
        let midY = min(originA.y, originB.y) - liftAmount

        // Phase 1: lift positions (both float up toward mixing zone)
        let liftA = CGPoint(x: midX - merge.cellSize * 0.35, y: midY)
        let liftB = CGPoint(x: midX + merge.cellSize * 0.35, y: midY)

        // Phase 2: merge position (converge to center)
        let mergePoint = CGPoint(x: midX, y: midY)

        ZStack {
            // --- Tile A ---
            tileShape(color: merge.colorA, resultColor: merge.resultColor, showResult: merged)
                .frame(width: tileSize, height: tileSize)
                .scaleEffect(scaleA)
                .rotationEffect(rotationA)
                .position(positionA(originA: originA, liftA: liftA, mergePoint: mergePoint))
                .opacity(opacityA)

            // --- Tile B ---
            tileShape(color: merge.colorB, resultColor: merge.resultColor, showResult: merged)
                .frame(width: tileSize, height: tileSize)
                .scaleEffect(scaleB)
                .rotationEffect(rotationB)
                .position(positionB(originB: originB, liftB: liftB, mergePoint: mergePoint))
                .opacity(opacityB)

            // --- Result tile (appears at merge, drops to posA) ---
            if merged {
                tileShape(color: merge.resultColor, resultColor: merge.resultColor, showResult: true)
                    .frame(width: merge.cellSize, height: merge.cellSize)
                    .scaleEffect(resultScale)
                    .shadow(color: merge.resultColor.opacity(0.4), radius: dropped ? 4 : 12, y: dropped ? 2 : 0)
                    .position(dropped ? originA : mergePoint)
            }
        }
        .allowsHitTesting(false)
        .onAppear { runAnimation() }
    }

    // MARK: - Computed animation state

    private var tileSize: CGFloat {
        merged ? merge.cellSize * 0.6 : merge.cellSize
    }

    private var scaleA: CGFloat {
        if merged { return 0.01 }
        if lifted { return 1.05 }
        return 1.0
    }

    private var scaleB: CGFloat {
        if merged { return 0.01 }
        if lifted { return 1.05 }
        return 1.0
    }

    private var rotationA: Angle {
        lifted && !merged ? .degrees(-3) : .zero
    }

    private var rotationB: Angle {
        lifted && !merged ? .degrees(3) : .zero
    }

    private var opacityA: Double {
        merged ? 0 : 1
    }

    private var opacityB: Double {
        merged ? 0 : 1
    }

    private var resultScale: CGFloat {
        if settled { return 1.0 }
        if dropped { return 1.1 }
        return 1.15
    }

    private func positionA(originA: CGPoint, liftA: CGPoint, mergePoint: CGPoint) -> CGPoint {
        if merged { return mergePoint }
        if lifted { return liftA }
        return originA
    }

    private func positionB(originB: CGPoint, liftB: CGPoint, mergePoint: CGPoint) -> CGPoint {
        if merged { return mergePoint }
        if lifted { return liftB }
        return originB
    }

    // MARK: - Tile shape (matches TileView styling)

    private func tileShape(color: Color, resultColor: Color, showResult: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: tileRadius)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.85), color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Glass highlight
            LinearGradient(
                colors: [.white.opacity(0.4), .white.opacity(0.12), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: tileRadius))

            // Top-edge catch
            VStack {
                RoundedRectangle(cornerRadius: tileRadius)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: 10)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: tileRadius))

            // Border
            RoundedRectangle(cornerRadius: tileRadius)
                .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
        }
    }

    // MARK: - Animation sequence

    private func runAnimation() {
        // Phase 1: Lift both tiles up (0-250ms)
        withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
            lifted = true
        }

        // Phase 2: Merge — tiles slide together + shrink (250-550ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.easeInOut(duration: 0.30)) {
                merged = true
            }
        }

        // Phase 3: Drop result to grid position (550-850ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
                dropped = true
            }
        }

        // Phase 4: Settle scale (750-950ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            withAnimation(.spring(response: 0.20, dampingFraction: 0.7)) {
                settled = true
            }
        }
    }
}
