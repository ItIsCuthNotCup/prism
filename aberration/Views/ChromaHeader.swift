//
//  ChromaHeader.swift
//  Blent – Color-Mixing Puzzle Game
//

import SwiftUI

/// Animated "BLENT" title — white text only visible through its chromatic aberration glow.
struct ChromaHeader: View {
    var fontSize: CGFloat = 28
    var tracking: CGFloat = 8

    private var baseFont: Font {
        .system(size: fontSize, weight: .black, design: .rounded)
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 0.5 + 0.5 * sin(t * 0.8)  // 0…1, ~8s full cycle
            let angle = t * 0.4                        // slow rotation

            // Chromatic offsets — RGB channels orbit the text
            let spread: CGFloat = 2.5 + CGFloat(breathe) * 2.0
            let rOff = channelOffset(angle: angle, spread: spread)
            let gOff = channelOffset(angle: angle + .pi * 2 / 3, spread: spread)
            let bOff = channelOffset(angle: angle + .pi * 4 / 3, spread: spread)
            let glowStrength = 0.5 + breathe * 0.4

            ZStack {
                // Red channel — strong, slightly blurred
                glowLayer(color: Color(hex: 0xFF3B5C), opacity: glowStrength,
                          blur: 1.5 + breathe * 1.5, offset: rOff)

                // Cyan/Green channel
                glowLayer(color: Color(hex: 0x00D4AA), opacity: glowStrength,
                          blur: 1.5 + breathe * 1.5, offset: gOff)

                // Blue channel
                glowLayer(color: Color(hex: 0x4488FF), opacity: glowStrength,
                          blur: 1.5 + breathe * 1.5, offset: bOff)

                // Soft diffuse halo underneath
                Text("BLENT")
                    .font(baseFont)
                    .tracking(tracking)
                    .foregroundStyle(.white.opacity(0.5 * breathe))
                    .blur(radius: 12 + CGFloat(breathe) * 8)

                // White base text — nearly invisible against light bg,
                // only readable through the chromatic glow around it
                Text("BLENT")
                    .font(baseFont)
                    .tracking(tracking)
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func glowLayer(color: Color, opacity: Double,
                           blur: Double, offset: CGSize) -> some View {
        Text("BLENT")
            .font(baseFont)
            .tracking(tracking)
            .foregroundStyle(color.opacity(opacity))
            .blur(radius: blur)
            .offset(offset)
    }

    private func channelOffset(angle: Double, spread: CGFloat) -> CGSize {
        CGSize(width: cos(angle) * spread, height: sin(angle) * spread * 0.6)
    }
}
