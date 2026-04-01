//
//  TunnelBackground.swift
//  Chromatose
//
//  Procedurally generated background — every session paints a
//  unique pattern from a random seed. Shapes, palettes, motion
//  styles, and layouts are all selected at init time.
//  Always-on ambient animation with frenzy intensification.
//

import SwiftUI

// MARK: - Seed-driven configuration

/// All randomness for one background "world."
private struct WorldSeed {
    let shape: ShapeKind
    let palette: [(r: Double, g: Double, b: Double)]
    let motionStyle: MotionStyle
    let ambientEffect: AmbientEffect
    let gridSpacing: CGFloat
    let baseAngleOffset: CGFloat
    let rotationSpeed: CGFloat     // how fast sub-shapes orbit
    let waveAmplitude: CGFloat     // for wave / spiral motion
    let waveFrequency: CGFloat

    enum ShapeKind: CaseIterable {
        case circle, square, diamond, triangle, ring, cross, star
    }

    enum MotionStyle: CaseIterable {
        case expand       // radial outward (original behaviour)
        case spiral       // orbit while separating
        case wave         // sine-wave drift
        case scatter      // random fixed offsets that scale
        case bloom        // all push outward from center of screen
    }

    /// Ambient background animation — always active, intensified during frenzy
    enum AmbientEffect: CaseIterable {
        case breathe      // slow zoom pulse on grid spacing
        case flow         // sine wave drift of all points
        case ripple       // concentric ring displacement from center
        case twist        // rotational displacement based on distance from center
        case drift        // all points slowly migrate in one direction
    }

    /// Build a fresh random world
    static func random() -> WorldSeed {
        let shape = ShapeKind.allCases.randomElement()!
        let palette = randomPalette()
        let motion = MotionStyle.allCases.randomElement()!
        let ambient = AmbientEffect.allCases.randomElement()!
        let spacing = CGFloat.random(in: 24...34)
        let angleOff = CGFloat.random(in: 0 ... .pi * 2)
        let rotSpeed = CGFloat.random(in: 0.08...0.35)
            * (Bool.random() ? 1 : -1)
        let wAmp = CGFloat.random(in: 0.5...2.0)
        let wFreq = CGFloat.random(in: 0.04...0.12)
        return WorldSeed(shape: shape, palette: palette,
                         motionStyle: motion, ambientEffect: ambient,
                         gridSpacing: spacing,
                         baseAngleOffset: angleOff,
                         rotationSpeed: rotSpeed,
                         waveAmplitude: wAmp, waveFrequency: wFreq)
    }

    // 10 curated vibrant zen palettes — exact hex values from design spec.
    private static let zenPalettes: [[(r: Double, g: Double, b: Double)]] = [
        // 1. Fresh Lagoon (#5ED3D1, #8AE6CF, #C7F9CC)
        [(0.369, 0.827, 0.820), (0.541, 0.902, 0.812), (0.780, 0.976, 0.800)],
        // 2. Sakura Glow (#FF8FAB, #FFB3C6, #FFC8DD)
        [(1.000, 0.561, 0.671), (1.000, 0.702, 0.776), (1.000, 0.784, 0.867)],
        // 3. Citrus Calm (#FFD166, #F4A261, #E9EDC9)
        [(1.000, 0.820, 0.400), (0.957, 0.635, 0.380), (0.914, 0.929, 0.788)],
        // 4. Tropical Zen (#06D6A0, #118AB2, #73C2FB)
        [(0.024, 0.839, 0.627), (0.067, 0.541, 0.698), (0.451, 0.761, 0.984)],
        // 5. Lavender Pop (#B388EB, #DDBDF1, #FFC6FF)
        [(0.702, 0.533, 0.922), (0.867, 0.741, 0.945), (1.000, 0.776, 1.000)],
        // 6. Soft Coral Reef (#FF6F61, #FF9A8B, #FCD5CE)
        [(1.000, 0.435, 0.380), (1.000, 0.604, 0.545), (0.988, 0.835, 0.808)],
        // 7. Modern Pastel Neon (#80FFDB, #64DFDF, #48BFE3)
        [(0.502, 1.000, 0.859), (0.392, 0.875, 0.875), (0.282, 0.749, 0.890)],
        // 8. Matcha Energy (#90DB3A, #B5E48C, #D9ED92)
        [(0.565, 0.859, 0.227), (0.710, 0.894, 0.549), (0.851, 0.929, 0.573)],
        // 9. Sunset Sorbet (#FF7F51, #FFB703, #FB8500)
        [(1.000, 0.498, 0.318), (1.000, 0.718, 0.012), (0.984, 0.522, 0.000)],
        // 10. Blueberry Cream (#4EA8DE, #72EFDD, #CDB4DB)
        [(0.306, 0.659, 0.871), (0.447, 0.937, 0.867), (0.804, 0.706, 0.859)],
    ]

    private static func randomPalette() -> [(r: Double, g: Double, b: Double)] {
        zenPalettes.randomElement()!
    }
}

// MARK: - Shape drawing helpers

private func drawShape(_ kind: WorldSeed.ShapeKind,
                       in context: inout GraphicsContext,
                       at center: CGPoint, radius: CGFloat,
                       color: Color) {
    switch kind {
    case .circle:
        let r = CGRect(x: center.x - radius, y: center.y - radius,
                       width: radius * 2, height: radius * 2)
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

// MARK: - View

struct TunnelBackground: View {
    var depth: Int
    var pulseID: Int
    var tapPulseID: Int = 0
    var gameID: Int = 0
    var frenzy: Bool = false

    @State private var roundPulse: CGFloat = 0
    @State private var tapPulse: CGFloat = 0
    @State private var seed = WorldSeed.random()

    var body: some View {
        // Zen mode: 1 fps — glacial, barely perceptible motion
        TimelineView(.animation(minimumInterval: 2.0, paused: false)) { timeline in
            let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate)

            Canvas { context, size in
                let d = CGFloat(depth)
                let baseSpacing = seed.gridSpacing

                // Ambient effect modifies spacing for breathe effect
                let spacing = ambientSpacing(base: baseSpacing, t: t, frenzy: frenzy)

                // Grey base: fades out as colour emerges
                let greyAlpha = max(0.0, 0.30 - d * 0.018)
                let greyRadius: CGFloat = 2.8

                // Colour: fades in
                let colorAlpha = min(d * 0.04, 0.65)
                let separation = d * 1.4 + roundPulse * 4 + tapPulse * 2
                let colorRadius = 2.0 + d * 0.35 + roundPulse * 1.5

                let cx = size.width / 2
                let cy = size.height / 2

                for gx in stride(from: spacing * 0.5, to: size.width + spacing, by: spacing) {
                    for gy in stride(from: spacing * 0.5, to: size.height + spacing, by: spacing) {

                        // Always-on ambient displacement
                        let (rgx, rgy) = ambientDisplace(
                            gx: gx, gy: gy, cx: cx, cy: cy,
                            t: t, frenzy: frenzy, size: size)

                        // -- Grey base dot --
                        if greyAlpha > 0.01 {
                            let rect = CGRect(x: rgx - greyRadius, y: rgy - greyRadius,
                                              width: greyRadius * 2, height: greyRadius * 2)
                            context.fill(Path(ellipseIn: rect),
                                         with: .color(Color(white: 0.35, opacity: greyAlpha)))
                        }

                        // -- Coloured sub-shapes --
                        if colorAlpha > 0.01 {
                            for (i, pal) in seed.palette.enumerated() {
                                let baseAngle = seed.baseAngleOffset
                                    + CGFloat(i) * .pi * 2 / CGFloat(seed.palette.count)

                                let (sx, sy) = subShapePosition(
                                    gx: rgx, gy: rgy, cx: cx, cy: cy,
                                    index: i, baseAngle: baseAngle,
                                    separation: separation, depth: d)

                                let color = Color(.sRGB, red: pal.r, green: pal.g,
                                                  blue: pal.b, opacity: colorAlpha)

                                drawShape(seed.shape, in: &context,
                                          at: CGPoint(x: sx, y: sy),
                                          radius: colorRadius, color: color)
                            }
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: pulseID) { _, _ in
            roundPulse = 1.0
            withAnimation(.easeOut(duration: 3.0)) { roundPulse = 0 }
        }
        // Tap pulse disabled — zen mode (no per-tap background jitter)
        .onChange(of: gameID) { _, _ in
            seed = WorldSeed.random()
        }
    }

    // MARK: - Ambient Effects

    /// Modify grid spacing for breathing effect — zen: very gentle
    private func ambientSpacing(base: CGFloat, t: CGFloat, frenzy: Bool) -> CGFloat {
        switch seed.ambientEffect {
        case .breathe:
            // Zen: glacial ±1px breathing
            let amp: CGFloat = 1.0
            let speed: CGFloat = 0.0075
            return base + sin(t * speed) * amp
        default:
            return base
        }
    }

    /// Displace a grid point based on the ambient effect — zen: glacial motion
    private func ambientDisplace(gx: CGFloat, gy: CGFloat,
                                  cx: CGFloat, cy: CGFloat,
                                  t: CGFloat, frenzy: Bool,
                                  size: CGSize) -> (CGFloat, CGFloat) {
        // Zen mode: all motion at ~10% of original, glacial speeds
        let intensity: CGFloat = 0.1

        switch seed.ambientEffect {
        case .breathe:
            return (gx, gy)

        case .flow:
            let wx = sin(gy * 0.018 + t * 0.0075) * 3.5 * intensity
            let wy = cos(gx * 0.015 + t * 0.006) * 2.8 * intensity
            return (gx + wx, gy + wy)

        case .ripple:
            let dx = gx - cx
            let dy = gy - cy
            let dist = sqrt(dx * dx + dy * dy)
            let wave = sin(dist * 0.04 - t * 0.006) * 3.0 * intensity
            let normX = dist > 1 ? dx / dist : 0
            let normY = dist > 1 ? dy / dist : 0
            return (gx + normX * wave, gy + normY * wave)

        case .twist:
            let dx = gx - cx
            let dy = gy - cy
            let dist = sqrt(dx * dx + dy * dy)
            let maxDist = sqrt(cx * cx + cy * cy)
            let normalizedDist = dist / max(maxDist, 1)
            let angle = sin(t * 0.005) * 0.007 * intensity * normalizedDist
            let cosA = cos(angle)
            let sinA = sin(angle)
            let rx = cx + (dx * cosA - dy * sinA)
            let ry = cy + (dx * sinA + dy * cosA)
            return (rx, ry)

        case .drift:
            let wx = sin(t * 0.005) * 2.0 * intensity
            let wy = cos(t * 0.0035) * 1.5 * intensity
            let localX = sin(gy * 0.01 + t * 0.005) * 0.5 * intensity
            let localY = cos(gx * 0.01 + t * 0.005) * 0.4 * intensity
            return (gx + wx + localX, gy + wy + localY)
        }
    }

    // MARK: - Motion

    /// Compute the offset position for a sub-shape based on the world's motion style.
    private func subShapePosition(
        gx: CGFloat, gy: CGFloat, cx: CGFloat, cy: CGFloat,
        index: Int, baseAngle: CGFloat,
        separation: CGFloat, depth: CGFloat
    ) -> (CGFloat, CGFloat) {

        switch seed.motionStyle {
        case .expand:
            // Original: push outward at fixed angles
            let angle = baseAngle
            return (gx + cos(angle) * separation,
                    gy + sin(angle) * separation)

        case .spiral:
            // Orbit while separating — angle rotates with depth
            let angle = baseAngle + depth * seed.rotationSpeed
            return (gx + cos(angle) * separation,
                    gy + sin(angle) * separation)

        case .wave:
            // Sine-wave offset — each colour rides a different phase
            let phase = CGFloat(index) * .pi * 2 / 3
            let waveX = sin(gy * seed.waveFrequency + phase + depth * 0.1)
                * seed.waveAmplitude * separation * 0.5
            let waveY = cos(gx * seed.waveFrequency + phase + depth * 0.1)
                * seed.waveAmplitude * separation * 0.3
            let angle = baseAngle
            return (gx + cos(angle) * separation + waveX,
                    gy + sin(angle) * separation + waveY)

        case .scatter:
            // Pseudo-random per-dot direction (deterministic from position)
            let hash = sin(gx * 127.1 + gy * 311.7 + CGFloat(index) * 73.3)
            let angle = hash * .pi * 2
            return (gx + cos(angle) * separation,
                    gy + sin(angle) * separation)

        case .bloom:
            // Push away from screen center
            let dx = gx - cx
            let dy = gy - cy
            let dist = max(sqrt(dx * dx + dy * dy), 1)
            let normX = dx / dist
            let normY = dy / dist
            let spread = separation * (1 + CGFloat(index) * 0.3)
            return (gx + normX * spread,
                    gy + normY * spread)
        }
    }
}
