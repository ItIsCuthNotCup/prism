//
//  TunnelBackground.swift
//  Stillhue
//
//  Procedurally generated background — a unique static pattern per round,
//  painted with colors the player has discovered through blending.
//  Pattern regenerates only on round-end or new game, never mid-round.
//

import SwiftUI

// MARK: - Deterministic PRNG (xorshift64)

/// Lightweight seedable random number generator for reproducible patterns.
private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    /// Returns a Double in [0, 1)
    mutating func nextDouble() -> Double {
        Double(next() % 1_000_000) / 1_000_000.0
    }

    /// Returns a CGFloat in [lo, hi)
    mutating func nextFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        let t = CGFloat(nextDouble())
        return range.lowerBound + t * (range.upperBound - range.lowerBound)
    }

    /// Returns an Int in [0, bound)
    mutating func nextInt(_ bound: Int) -> Int {
        guard bound > 0 else { return 0 }
        return Int(next() % UInt64(bound))
    }

    /// Returns true with given probability [0..1]
    mutating func chance(_ probability: Double) -> Bool {
        nextDouble() < probability
    }
}

// MARK: - Shape types

private enum MarkShape: CaseIterable {
    case circle, square, diamond, triangle, ring, cross, star, dot
}

private func drawMark(_ kind: MarkShape,
                      in context: inout GraphicsContext,
                      at center: CGPoint, radius: CGFloat,
                      color: Color) {
    switch kind {
    case .circle:
        let r = CGRect(x: center.x - radius, y: center.y - radius,
                       width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: r), with: .color(color))

    case .dot:
        // Smaller, softer circle
        let r = CGRect(x: center.x - radius * 0.6, y: center.y - radius * 0.6,
                       width: radius * 1.2, height: radius * 1.2)
        context.fill(Path(ellipseIn: r), with: .color(color))

    case .square:
        let r = CGRect(x: center.x - radius, y: center.y - radius,
                       width: radius * 2, height: radius * 2)
        context.fill(Path(r), with: .color(color))

    case .diamond:
        var p = Path()
        p.move(to: CGPoint(x: center.x, y: center.y - radius))
        p.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        p.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        p.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        p.closeSubpath()
        context.fill(p, with: .color(color))

    case .triangle:
        var p = Path()
        p.move(to: CGPoint(x: center.x, y: center.y - radius))
        p.addLine(to: CGPoint(x: center.x + radius * 0.87, y: center.y + radius * 0.5))
        p.addLine(to: CGPoint(x: center.x - radius * 0.87, y: center.y + radius * 0.5))
        p.closeSubpath()
        context.fill(p, with: .color(color))

    case .ring:
        let outer = CGRect(x: center.x - radius, y: center.y - radius,
                           width: radius * 2, height: radius * 2)
        let inner = CGRect(x: center.x - radius * 0.5, y: center.y - radius * 0.5,
                           width: radius, height: radius)
        var p = Path()
        p.addEllipse(in: outer)
        p.addEllipse(in: inner)
        context.fill(p, with: .color(color), style: FillStyle(eoFill: true))

    case .cross:
        let t = radius * 0.35
        var p = Path()
        p.addRect(CGRect(x: center.x - t, y: center.y - radius,
                         width: t * 2, height: radius * 2))
        p.addRect(CGRect(x: center.x - radius, y: center.y - t,
                         width: radius * 2, height: t * 2))
        context.fill(p, with: .color(color))

    case .star:
        var p = Path()
        for i in 0..<5 {
            let outerAngle = CGFloat(i) * .pi * 2 / 5 - .pi / 2
            let innerAngle = outerAngle + .pi / 5
            let op = CGPoint(x: center.x + cos(outerAngle) * radius,
                             y: center.y + sin(outerAngle) * radius)
            let ip = CGPoint(x: center.x + cos(innerAngle) * radius * 0.4,
                             y: center.y + sin(innerAngle) * radius * 0.4)
            if i == 0 { p.move(to: op) } else { p.addLine(to: op) }
            p.addLine(to: ip)
        }
        p.closeSubpath()
        context.fill(p, with: .color(color))
    }
}

// MARK: - Layout strategies

/// How marks are distributed across the canvas.
private enum LayoutStyle: CaseIterable {
    case scatteredGrid    // grid with heavy jitter + sparse skip
    case freeScatter      // fully random positions
    case radialBurst      // marks emanate from center in rings
    case diagonalBands    // marks cluster along diagonal lines
    case clusters         // small random groups scattered around
    case confetti         // lots of tiny marks, very sparse
    case cornerBloom      // marks concentrate toward corners/edges
}

// MARK: - Pattern configuration (generated per round)

private struct PatternConfig {
    let layout: LayoutStyle
    let shapes: [MarkShape]         // 1-3 shapes used this round
    let markCount: Int              // how many colored marks to draw
    let sizeRange: ClosedRange<CGFloat>
    let alphaRange: ClosedRange<CGFloat>
    let gridSpacing: CGFloat
    let jitter: CGFloat             // position jitter for grid layouts
    let rngSeed: UInt64

    static func generate(seed: UInt64, depth: Int) -> PatternConfig {
        var rng = SeededRNG(seed: seed)

        let layout = LayoutStyle.allCases[rng.nextInt(LayoutStyle.allCases.count)]

        // Pick 1-3 shape types for this round
        let shapeCount = rng.nextInt(3) + 1
        var shapes: [MarkShape] = []
        for _ in 0..<shapeCount {
            shapes.append(MarkShape.allCases[rng.nextInt(MarkShape.allCases.count)])
        }

        // Depth influences mark count and size — more colors = richer canvas
        let baseCount = 60 + rng.nextInt(80)                    // 60-140 marks
        let depthBonus = min(depth * 3, 60)                     // up to 60 more
        let markCount = baseCount + depthBonus

        let minSize = rng.nextFloat(in: 2.5...4.0)
        let maxSize = minSize + rng.nextFloat(in: 2.0...6.0)

        // Alpha: always subtle, varies by round personality
        let minAlpha = rng.nextFloat(in: 0.06...0.10)
        let maxAlpha = rng.nextFloat(in: 0.14...0.22)

        let spacing = rng.nextFloat(in: 30...50)
        let jitter = rng.nextFloat(in: 5...20)

        return PatternConfig(
            layout: layout,
            shapes: shapes,
            markCount: markCount,
            sizeRange: minSize...maxSize,
            alphaRange: minAlpha...maxAlpha,
            gridSpacing: spacing,
            jitter: jitter,
            rngSeed: seed
        )
    }
}

// MARK: - View

struct TunnelBackground: View {
    var depth: Int
    var pulseID: Int
    var tapPulseID: Int = 0
    var gameID: Int = 0
    var frenzy: Bool = false
    /// Wheel indices of colors the player has discovered through blending
    var discoveredColorIndices: Set<Int> = []

    /// Seed for the current pattern — changes only on round-end or new game
    @State private var patternSeed: UInt64 = 1

    var body: some View {
        Canvas { context, size in
            var rng = SeededRNG(seed: patternSeed)
            let config = PatternConfig.generate(seed: patternSeed, depth: depth)

            // --- Layer 1: Grey dot grid (graph paper, always present) ---
            let isDark = AppTheme.shared.isDark
            let greyAlpha = max(isDark ? 0.04 : 0.08, (isDark ? 0.15 : 0.30) - CGFloat(depth) * 0.012)
            let dotSpacing: CGFloat = 28.0
            let dotRadius: CGFloat = 1.2
            let dotBrightness: CGFloat = isDark ? 0.65 : 0.35

            for gx in stride(from: dotSpacing * 0.5, to: size.width, by: dotSpacing) {
                for gy in stride(from: dotSpacing * 0.5, to: size.height, by: dotSpacing) {
                    let rect = CGRect(x: gx - dotRadius, y: gy - dotRadius,
                                      width: dotRadius * 2, height: dotRadius * 2)
                    context.fill(Path(ellipseIn: rect),
                                 with: .color(Color(white: dotBrightness, opacity: greyAlpha)))
                }
            }

            // --- Layer 2: Colored marks from discovered palette ---
            guard !discoveredColorIndices.isEmpty else { return }

            let palette: [(r: Double, g: Double, b: Double)] = discoveredColorIndices.sorted().map { idx in
                let hex = PrismColor.hexValues[idx]
                let r = Double((hex >> 16) & 0xFF) / 255.0
                let g = Double((hex >> 8) & 0xFF) / 255.0
                let b = Double(hex & 0xFF) / 255.0
                return (r, g, b)
            }

            // Generate mark positions based on layout style
            let marks = generatePositions(
                layout: config.layout,
                count: config.markCount,
                size: size,
                config: config,
                rng: &rng
            )

            for pos in marks {
                // Pick a color from the palette
                let palIdx = rng.nextInt(palette.count)
                let pal = palette[palIdx]

                // Pick a shape from this round's shape set
                let shape = config.shapes[rng.nextInt(config.shapes.count)]

                // Randomize size and opacity within this round's range
                let radius = rng.nextFloat(in: config.sizeRange)
                let alpha = rng.nextFloat(in: config.alphaRange)

                let color = Color(.sRGB, red: pal.r, green: pal.g,
                                  blue: pal.b, opacity: Double(alpha))
                drawMark(shape, in: &context,
                         at: pos, radius: radius, color: color)
            }
        }
        .drawingGroup()   // Rasterize to Metal texture — avoids re-executing Canvas on parent redraws
        .ignoresSafeArea()
        .onChange(of: pulseID) { _, _ in
            // Round ended — new pattern with new seed
            patternSeed = patternSeed &+ UInt64(pulseID) &* 6364136223846793005 &+ 1
        }
        .onChange(of: gameID) { _, _ in
            // New game — completely fresh pattern
            patternSeed = UInt64(gameID) &* 2862933555777941757 &+ 3037000493
        }
        .onAppear {
            patternSeed = UInt64(gameID &+ 1) &* 2862933555777941757 &+ UInt64(pulseID)
        }
    }

    // MARK: - Position generation

    private func generatePositions(
        layout: LayoutStyle,
        count: Int,
        size: CGSize,
        config: PatternConfig,
        rng: inout SeededRNG
    ) -> [CGPoint] {
        switch layout {
        case .scatteredGrid:
            return scatteredGrid(count: count, size: size, config: config, rng: &rng)
        case .freeScatter:
            return freeScatter(count: count, size: size, rng: &rng)
        case .radialBurst:
            return radialBurst(count: count, size: size, rng: &rng)
        case .diagonalBands:
            return diagonalBands(count: count, size: size, rng: &rng)
        case .clusters:
            return clusterLayout(count: count, size: size, rng: &rng)
        case .confetti:
            return freeScatter(count: count + 40, size: size, rng: &rng)
        case .cornerBloom:
            return cornerBloom(count: count, size: size, rng: &rng)
        }
    }

    /// Grid-based with heavy jitter and ~50% skip
    private func scatteredGrid(count: Int, size: CGSize, config: PatternConfig, rng: inout SeededRNG) -> [CGPoint] {
        var points: [CGPoint] = []
        let spacing = config.gridSpacing
        let jitter = config.jitter
        for gx in stride(from: spacing * 0.5, to: size.width + spacing, by: spacing) {
            for gy in stride(from: spacing * 0.5, to: size.height + spacing, by: spacing) {
                guard rng.chance(0.45) else { continue }
                let x = gx + rng.nextFloat(in: (-jitter)...jitter)
                let y = gy + rng.nextFloat(in: (-jitter)...jitter)
                points.append(CGPoint(x: x, y: y))
                if points.count >= count { return points }
            }
        }
        return points
    }

    /// Fully random positions
    private func freeScatter(count: Int, size: CGSize, rng: inout SeededRNG) -> [CGPoint] {
        (0..<count).map { _ in
            CGPoint(x: rng.nextFloat(in: 0...size.width),
                    y: rng.nextFloat(in: 0...size.height))
        }
    }

    /// Marks in concentric rings from center
    private func radialBurst(count: Int, size: CGSize, rng: inout SeededRNG) -> [CGPoint] {
        var points: [CGPoint] = []
        let cx = size.width / 2, cy = size.height / 2
        let maxR = sqrt(cx * cx + cy * cy)
        let ringCount = 6 + rng.nextInt(6)  // 6-12 rings
        let marksPerRing = count / ringCount

        for ring in 0..<ringCount {
            let r = maxR * CGFloat(ring + 1) / CGFloat(ringCount + 1)
            let jitter = rng.nextFloat(in: 5...15)
            for _ in 0..<marksPerRing {
                let angle = rng.nextFloat(in: 0...(CGFloat.pi * 2))
                let rr = r + rng.nextFloat(in: (-jitter)...jitter)
                points.append(CGPoint(x: cx + cos(angle) * rr,
                                      y: cy + sin(angle) * rr))
            }
        }
        return points
    }

    /// Marks cluster along diagonal bands
    private func diagonalBands(count: Int, size: CGSize, rng: inout SeededRNG) -> [CGPoint] {
        var points: [CGPoint] = []
        let bandCount = 4 + rng.nextInt(5)  // 4-8 bands
        let bandWidth = rng.nextFloat(in: 20...50)
        let diagonal = size.width + size.height
        let bandSpacing = diagonal / CGFloat(bandCount + 1)

        for band in 0..<bandCount {
            let bandCenter = bandSpacing * CGFloat(band + 1)
            let marksInBand = count / bandCount
            for _ in 0..<marksInBand {
                // Point along the diagonal line x + y = bandCenter, with jitter
                let x = rng.nextFloat(in: (-20)...size.width + 20)
                let targetY = bandCenter - x
                let y = targetY + rng.nextFloat(in: (-bandWidth)...bandWidth)
                points.append(CGPoint(x: x, y: y))
            }
        }
        return points
    }

    /// Small random groups of marks
    private func clusterLayout(count: Int, size: CGSize, rng: inout SeededRNG) -> [CGPoint] {
        var points: [CGPoint] = []
        let clusterCount = 5 + rng.nextInt(8)  // 5-12 clusters
        let marksPerCluster = count / clusterCount

        for _ in 0..<clusterCount {
            let cx = rng.nextFloat(in: 0...size.width)
            let cy = rng.nextFloat(in: 0...size.height)
            let spread = rng.nextFloat(in: 20...60)

            for _ in 0..<marksPerCluster {
                let x = cx + rng.nextFloat(in: (-spread)...spread)
                let y = cy + rng.nextFloat(in: (-spread)...spread)
                points.append(CGPoint(x: x, y: y))
            }
        }
        return points
    }

    /// Marks concentrate toward corners and edges
    private func cornerBloom(count: Int, size: CGSize, rng: inout SeededRNG) -> [CGPoint] {
        var points: [CGPoint] = []
        let corners: [CGPoint] = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: size.width, y: 0),
            CGPoint(x: 0, y: size.height),
            CGPoint(x: size.width, y: size.height)
        ]

        for _ in 0..<count {
            let corner = corners[rng.nextInt(4)]
            let spread = rng.nextFloat(in: 40...180)
            let x = corner.x + rng.nextFloat(in: (-spread)...spread)
            let y = corner.y + rng.nextFloat(in: (-spread)...spread)
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
}
