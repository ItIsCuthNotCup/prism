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

    // Palette generators — always 3 colours, varied hue strategies
    private static func randomPalette() -> [(r: Double, g: Double, b: Double)] {
        let strategy = Int.random(in: 0...5)
        switch strategy {
        case 0: return triadic()
        case 1: return complementary()
        case 2: return analogous()
        case 3: return neon()
        case 4: return pastel()
        default: return classic()
        }
    }

    private static func hsl(_ h: Double, _ s: Double, _ l: Double)
        -> (r: Double, g: Double, b: Double) {
        let c = (1 - abs(2 * l - 1)) * s
        let hp = h / 60.0
        let x = c * (1 - abs(hp.truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2
        var r = 0.0, g = 0.0, b = 0.0
        if hp < 1 { r = c; g = x }
        else if hp < 2 { r = x; g = c }
        else if hp < 3 { g = c; b = x }
        else if hp < 4 { g = x; b = c }
        else if hp < 5 { r = x; b = c }
        else { r = c; b = x }
        return (r + m, g + m, b + m)
    }

    private static func triadic() -> [(r: Double, g: Double, b: Double)] {
        let base = Double.random(in: 0..<360)
        return [hsl(base, 0.85, 0.55),
                hsl((base + 120).truncatingRemainder(dividingBy: 360), 0.85, 0.55),
                hsl((base + 240).truncatingRemainder(dividingBy: 360), 0.85, 0.55)]
    }
    private static func complementary() -> [(r: Double, g: Double, b: Double)] {
        let base = Double.random(in: 0..<360)
        return [hsl(base, 0.9, 0.50),
                hsl((base + 180).truncatingRemainder(dividingBy: 360), 0.9, 0.50),
                hsl((base + 90).truncatingRemainder(dividingBy: 360), 0.6, 0.60)]
    }
    private static func analogous() -> [(r: Double, g: Double, b: Double)] {
        let base = Double.random(in: 0..<360)
        return [hsl(base, 0.80, 0.50),
                hsl((base + 30).truncatingRemainder(dividingBy: 360), 0.80, 0.55),
                hsl((base + 60).truncatingRemainder(dividingBy: 360), 0.80, 0.50)]
    }
    private static func neon() -> [(r: Double, g: Double, b: Double)] {
        let base = Double.random(in: 0..<360)
        return [hsl(base, 1.0, 0.55),
                hsl((base + 150).truncatingRemainder(dividingBy: 360), 1.0, 0.50),
                hsl((base + 210).truncatingRemainder(dividingBy: 360), 1.0, 0.55)]
    }
    private static func pastel() -> [(r: Double, g: Double, b: Double)] {
        let base = Double.random(in: 0..<360)
        return [hsl(base, 0.65, 0.72),
                hsl((base + 120).truncatingRemainder(dividingBy: 360), 0.55, 0.72),
                hsl((base + 240).truncatingRemainder(dividingBy: 360), 0.60, 0.72)]
    }
    private static func classic() -> [(r: Double, g: Double, b: Double)] {
        return [(0.95, 0.85, 0.10),   // Yellow
                (0.95, 0.35, 0.10),   // Red-Orange
                (0.15, 0.25, 0.95)]   // Blue
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
        // Always animate: 6 fps ambient, 10 fps during frenzy
        TimelineView(.animation(minimumInterval: frenzy ? 1.0 / 10 : 1.0 / 6, paused: false)) { timeline in
            let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate)

            Canvas { context, size in
                let d = CGFloat(depth)
                let baseSpacing = seed.gridSpacing

                // Ambient effect modifies spacing for breathe effect
                let spacing = ambientSpacing(base: baseSpacing, t: t, frenzy: frenzy)

                // Grey base: fades out as colour emerges
                let greyAlpha = max(0.0, 0.22 - d * 0.018)
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
            withAnimation(.easeOut(duration: 1.8)) { roundPulse = 0 }
        }
        .onChange(of: tapPulseID) { _, _ in
            tapPulse = 1.0
            withAnimation(.easeOut(duration: 0.4)) { tapPulse = 0 }
        }
        .onChange(of: gameID) { _, _ in
            seed = WorldSeed.random()
        }
    }

    // MARK: - Ambient Effects

    /// Modify grid spacing for breathing effect
    private func ambientSpacing(base: CGFloat, t: CGFloat, frenzy: Bool) -> CGFloat {
        switch seed.ambientEffect {
        case .breathe:
            // Slow zoom pulse: ±2px normal, ±4px frenzy
            let amp: CGFloat = frenzy ? 4.0 : 2.0
            let speed: CGFloat = frenzy ? 0.2 : 0.1
            return base + sin(t * speed) * amp
        default:
            return base
        }
    }

    /// Displace a grid point based on the ambient effect
    private func ambientDisplace(gx: CGFloat, gy: CGFloat,
                                  cx: CGFloat, cy: CGFloat,
                                  t: CGFloat, frenzy: Bool,
                                  size: CGSize) -> (CGFloat, CGFloat) {
        // Big displacement so it's visible, ~70% of the "too fast" speed
        let intensity: CGFloat = frenzy ? 2.5 : 1.0

        switch seed.ambientEffect {
        case .breathe:
            return (gx, gy)

        case .flow:
            let wx = sin(gy * 0.018 + t * 0.16) * 3.5 * intensity
            let wy = cos(gx * 0.015 + t * 0.13) * 2.8 * intensity
            return (gx + wx, gy + wy)

        case .ripple:
            let dx = gx - cx
            let dy = gy - cy
            let dist = sqrt(dx * dx + dy * dy)
            let wave = sin(dist * 0.04 - t * 0.14) * 3.0 * intensity
            let normX = dist > 1 ? dx / dist : 0
            let normY = dist > 1 ? dy / dist : 0
            return (gx + normX * wave, gy + normY * wave)

        case .twist:
            let dx = gx - cx
            let dy = gy - cy
            let dist = sqrt(dx * dx + dy * dy)
            let maxDist = sqrt(cx * cx + cy * cy)
            let normalizedDist = dist / max(maxDist, 1)
            let angle = sin(t * 0.08) * 0.04 * intensity * normalizedDist
            let cosA = cos(angle)
            let sinA = sin(angle)
            let rx = cx + (dx * cosA - dy * sinA)
            let ry = cy + (dx * sinA + dy * cosA)
            return (rx, ry)

        case .drift:
            let wx = sin(t * 0.07) * 4.0 * intensity
            let wy = cos(t * 0.05) * 3.0 * intensity
            let localX = sin(gy * 0.01 + t * 0.08) * 1.0 * intensity
            let localY = cos(gx * 0.01 + t * 0.07) * 0.8 * intensity
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
