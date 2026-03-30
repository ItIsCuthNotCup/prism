//
//  TunnelBackground.swift
//  Blent – Color-Mixing Puzzle Game
//
//  Background: a grid of grey dots that progressively split into
//  their hidden primary-color components (Yellow, Red, Blue).
//  As rounds increase, the colored sub-dots separate further
//  and grow larger.
//

import SwiftUI

struct TunnelBackground: View {
    var depth: Int
    var pulseID: Int
    var tapPulseID: Int = 0

    @State private var roundPulse: CGFloat = 0
    @State private var tapPulse: CGFloat = 0

    // The three hidden primaries inside each "grey" dot
    private let primaries: [(r: Double, g: Double, b: Double, angle: CGFloat)] = [
        (0.95, 0.85, 0.10, 0),                  // Yellow — 0°
        (0.95, 0.35, 0.10, .pi * 2 / 3),        // Red/Orange — 120°
        (0.15, 0.25, 0.95, .pi * 4 / 3),        // Blue — 240°
    ]

    var body: some View {
        Canvas { context, size in
            let d = CGFloat(depth)
            let gridSpacing: CGFloat = 28

            // Grey dot: visible at start, fades as color emerges
            let greyAlpha = max(0.0, 0.22 - d * 0.018)
            let greyRadius: CGFloat = 2.8

            // Colored sub-dots: appear gradually, grow, separate
            let colorAlpha = min(d * 0.04, 0.65)
            let separation = d * 1.4 + roundPulse * 4 + tapPulse * 2
            let colorRadius = 2.0 + d * 0.35 + roundPulse * 1.5

            for gx in stride(from: gridSpacing * 0.5, to: size.width, by: gridSpacing) {
                for gy in stride(from: gridSpacing * 0.5, to: size.height, by: gridSpacing) {

                    // -- Grey base dot --
                    if greyAlpha > 0.01 {
                        let rect = CGRect(x: gx - greyRadius, y: gy - greyRadius,
                                          width: greyRadius * 2, height: greyRadius * 2)
                        context.fill(Path(ellipseIn: rect),
                                     with: .color(Color(white: 0.35, opacity: greyAlpha)))
                    }

                    // -- Colored sub-dots --
                    if colorAlpha > 0.01 {
                        for p in primaries {
                            let sx = gx + cos(p.angle) * separation
                            let sy = gy + sin(p.angle) * separation

                            let rect = CGRect(x: sx - colorRadius, y: sy - colorRadius,
                                              width: colorRadius * 2, height: colorRadius * 2)
                            context.fill(Path(ellipseIn: rect),
                                         with: .color(Color(.sRGB, red: p.r, green: p.g, blue: p.b,
                                                            opacity: colorAlpha)))
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
    }
}
