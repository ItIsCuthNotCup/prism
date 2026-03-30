//
//  TunnelBackground.swift
//  Blent – Color-Mixing Puzzle Game
//
//  Chromatic aberration tunnel: dot grid with radial zoom that deepens each round.
//  Vanishing point sits behind the target tile (upper-center).
//  RGB channels split along radial lines — red extends further, blue contracts.
//  Round-complete: big outward pulse that settles at new intensity.
//  Tile tap: subtle inward contraction (dots sucked toward center, then relax).
//

import SwiftUI

struct TunnelBackground: View {
    /// Number of rounds completed — drives tunnel intensity
    var depth: Int
    /// Matches depth — fires round-complete pulse
    var pulseID: Int
    /// Increments on every tile tap — fires a subtle inward pulse
    var tapPulseID: Int = 0

    // Round-complete pulse (outward burst)
    @State private var roundPulse: CGFloat = 0
    // Tap pulse (inward contraction)
    @State private var tapPulse: CGFloat = 0

    // Combined intensity
    private var totalIntensity: CGFloat {
        let base = min(CGFloat(depth) * 0.025, 0.6)
        return base + roundPulse * 0.35
    }

    var body: some View {
        Canvas { context, size in
            let dotSpacing: CGFloat = 20
            let dotRadius: CGFloat = 0.8
            let intensity = totalIntensity
            let inward = tapPulse  // 0…1, how much dots pull inward

            // Vanishing point: upper-center, behind the target area
            let vanish = CGPoint(x: size.width / 2, y: size.height * 0.32)
            let maxDist = sqrt(size.width * size.width + size.height * size.height) * 0.5

            // Always draw base dots — with inward pull applied
            for x in stride(from: CGFloat(0), to: size.width, by: dotSpacing) {
                for y in stride(from: CGFloat(0), to: size.height, by: dotSpacing) {
                    // Inward pull: shift dots toward vanishing point
                    let dx = x - vanish.x
                    let dy = y - vanish.y
                    let dist = sqrt(dx * dx + dy * dy)
                    let normDist = min(dist / maxDist, 1.5)

                    // Pull amount: proportional to distance from center
                    let pullStrength = inward * normDist * 6
                    let angle = atan2(dy, dx)
                    let drawX = x - cos(angle) * pullStrength
                    let drawY = y - sin(angle) * pullStrength

                    // Base dot opacity: slightly brighter during tap pulse
                    let baseOpacity = 0.06 + inward * 0.03 * normDist

                    let rect = CGRect(
                        x: drawX - dotRadius, y: drawY - dotRadius,
                        width: dotRadius * 2, height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(baseOpacity)))
                }
            }

            // Only draw chromatic channels if there's any intensity
            guard intensity > 0.005 else { return }

            // Three channels with different radial spread multipliers
            let channels: [(red: CGFloat, green: CGFloat, blue: CGFloat, spread: CGFloat)] = [
                (1.0, 0.23, 0.36, 1.08 + intensity * 0.15),   // Red — extends further
                (0.0, 0.83, 0.67, 1.0),                         // Cyan — baseline
                (0.27, 0.53, 1.0, 0.92 - intensity * 0.1),     // Blue — contracts
            ]

            for ch in channels {
                let color = Color(red: ch.red, green: ch.green, blue: ch.blue)
                let spreadMult = ch.spread

                for x in stride(from: CGFloat(0), to: size.width, by: dotSpacing) {
                    for y in stride(from: CGFloat(0), to: size.height, by: dotSpacing) {
                        let dx = x - vanish.x
                        let dy = y - vanish.y
                        let dist = sqrt(dx * dx + dy * dy)
                        let normDist = min(dist / maxDist, 1.5)
                        let angle = atan2(dy, dx)

                        // Radial zoom: push dots outward (minus inward pull from tap)
                        let zoomShift = normDist * normDist * intensity * spreadMult * 40
                            - inward * normDist * 6
                        let shiftedX = x + cos(angle) * zoomShift
                        let shiftedY = y + sin(angle) * zoomShift

                        // Streak length for radial blur effect
                        let streakLen = normDist * intensity * spreadMult * 8

                        // Opacity: stronger at edges
                        let dotOpacity = intensity * 0.55 * (0.15 + normDist * 0.85)
                        if dotOpacity < 0.01 { continue }

                        if streakLen > 1.5 {
                            let sdx = cos(angle) * streakLen
                            let sdy = sin(angle) * streakLen
                            var path = Path()
                            path.move(to: CGPoint(x: shiftedX - sdx, y: shiftedY - sdy))
                            path.addLine(to: CGPoint(x: shiftedX + sdx, y: shiftedY + sdy))
                            context.stroke(path, with: .color(color.opacity(dotOpacity)),
                                           lineWidth: dotRadius * 1.5)
                        } else {
                            let rect = CGRect(
                                x: shiftedX - dotRadius, y: shiftedY - dotRadius,
                                width: dotRadius * 2, height: dotRadius * 2
                            )
                            context.fill(Path(ellipseIn: rect),
                                         with: .color(color.opacity(dotOpacity)))
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: pulseID) { _, _ in
            roundPulse = 1.0
            withAnimation(.easeOut(duration: 1.5)) {
                roundPulse = 0
            }
        }
        .onChange(of: tapPulseID) { _, _ in
            tapPulse = 1.0
            withAnimation(.easeOut(duration: 0.35)) {
                tapPulse = 0
            }
        }
    }
}
