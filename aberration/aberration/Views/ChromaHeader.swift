//
//  ChromaHeader.swift
//  Blent – Color-Mixing Puzzle Game
//
//  Iridescent droplet logo with chromatic glow that slowly breathes.
//  Uses implicit SwiftUI animations instead of TimelineView for zero
//  per-frame CPU cost (GPU-interpolated).
//

import SwiftUI

// MARK: - Teardrop Shape

struct Teardrop: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w * 0.95, y: h * 0.35),
            control2: CGPoint(x: w * 0.85, y: h * 0.75)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: w * 0.15, y: h * 0.75),
            control2: CGPoint(x: w * 0.05, y: h * 0.35)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Logo View

/// Iridescent droplet symbol used as the app logo.
/// Uses implicit animations for breathing — zero per-frame CPU cost.
struct ChromaHeader: View {
    var fontSize: CGFloat = 28
    var tracking: CGFloat = 8 // unused, kept for call-site compat

    @State private var breatheIn = false

    private var dropSize: CGFloat { fontSize * 1.2 }

    private var glowBlur: CGFloat { breatheIn ? 10 : 6 }
    private var glowOpacity: Double { breatheIn ? 0.9 : 0.6 }

    var body: some View {
        ZStack {
            // Outer chromatic glow — breathes via implicit animation
            Teardrop()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(hex: 0xFF3B5C),
                            Color(hex: 0xFF9500),
                            Color(hex: 0xFFD60A),
                            Color(hex: 0x30D158),
                            Color(hex: 0x00D4AA),
                            Color(hex: 0x5AC8FA),
                            Color(hex: 0x5856D6),
                            Color(hex: 0xFF3B5C),
                        ],
                        center: .center
                    )
                )
                .frame(width: dropSize, height: dropSize * 1.25)
                .blur(radius: glowBlur)
                .opacity(glowOpacity)

            // Main droplet — iridescent fill (static gradient, no rotation)
            Teardrop()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(hex: 0xFF5E6C),
                            Color(hex: 0xFFAA5C),
                            Color(hex: 0xF0E050),
                            Color(hex: 0x50E080),
                            Color(hex: 0x40D0C0),
                            Color(hex: 0x60B0F0),
                            Color(hex: 0xA080E0),
                            Color(hex: 0xFF5E6C),
                        ],
                        center: .center
                    )
                )
                .frame(width: dropSize, height: dropSize * 1.25)
                .overlay(
                    Teardrop()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.7), .white.opacity(0.0)],
                                center: .init(x: 0.35, y: 0.3),
                                startRadius: 0,
                                endRadius: dropSize * 0.6
                            )
                        )
                )
                .clipShape(Teardrop())
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                breatheIn = true
            }
        }
        .frame(maxWidth: .infinity)
    }
}
