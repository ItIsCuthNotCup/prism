//
//  TunnelBackground.swift
//  Blent – Color-Mixing Puzzle Game
//
//  Chromatic aberration tunnel: dot grid with radial zoom that deepens each round.
//  Vanishing point sits behind the target tile (upper-center).
//  RGB channels split along radial lines — red extends further, blue contracts.
//  Pulses on round complete, then settles at new intensity.
//

import SwiftUI

struct TunnelBackground: View {
    /// Number of rounds completed — drives tunnel intensity
    var depth: Int
    /// Matches depth — used to detect changes and fire pulse
    var pulseID: Int

    @State private var pulseAmount: CGFloat = 0

    // Derived intensity (base + pulse)
    private var totalIntensity: CGFloat {
        let base = min(CGFloat(depth) * 0.025, 0.6)
        return base + pulseAmount * 0.35
    }

    var body: some View {
        Canvas { context, size in
            let dotSpacing: CGFloat = 20
            let dotRadius: CGFloat = 0.8
            let intensity = totalIntensity

            // Vanishing point: upper-center, behind the target area
            let vanish = CGPoint(x: size.width / 2, y: size.height * 0.32)
            let maxDist = sqrt(size.width * size.width + size.height * size.height) * 0.5

            // Always draw neutral base dots
            for x in stride(from: CGFloat(0), to: size.width, by: dotSpacing) {
                for y in stride(from: CGFloat(0), to: size.height, by: dotSpacing) {
                    let rect = CGRect(
                        x: x - dotRadius, y: y - dotRadius,
                        width: dotRadius * 2, height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.06)))
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

                        // Radial zoom: push dots outward
                        let zoomShift = normDist * normDist * intensity * spreadMult * 40
                        let angle = atan2(dy, dx)
                        let shiftedX = x + cos(angle) * zoomShift
                        let shiftedY = y + sin(angle) * zoomShift

                        // Streak length for radial blur effect
                        let streakLen = normDist * intensity * spreadMult * 8

                        // Opacity: stronger at edges
                        let dotOpacity = intensity * 0.55 * (0.15 + normDist * 0.85)
                        if dotOpacity < 0.01 { continue }

                        if streakLen > 1.5 {
                            // Radial streak
                            let sdx = cos(angle) * streakLen
                            let sdy = sin(angle) * streakLen
                            var path = Path()
                            path.move(to: CGPoint(x: shiftedX - sdx, y: shiftedY - sdy))
                            path.addLine(to: CGPoint(x: shiftedX + sdx, y: shiftedY + sdy))
                            context.stroke(path, with: .color(color.opacity(dotOpacity)),
                                           lineWidth: dotRadius * 1.5)
                        } else {
                            // Dot
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
            pulseAmount = 1.0
            withAnimation(.easeOut(duration: 1.5)) {
                pulseAmount = 0
            }
        }
    }
}
