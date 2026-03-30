//
//  ChromaHeader.swift
//  Blent – Color-Mixing Puzzle Game
//
//  Iridescent droplet logo with chromatic glow that slowly breathes.
//

import SwiftUI

// MARK: - Teardrop Shape

struct Teardrop: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        // Rounded teardrop: wide bottom, pointed top
        var path = Path()
        // Start at top (the pointed tip)
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        // Right curve down to bottom
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w * 0.95, y: h * 0.35),
            control2: CGPoint(x: w * 0.85, y: h * 0.75)
        )
        // Left curve back up to top
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
/// `ChromaHeader` name kept for backward compatibility with ContentView call sites.
struct ChromaHeader: View {
    // fontSize now controls the droplet size (ignored tracking)
    var fontSize: CGFloat = 28
    var tracking: CGFloat = 8 // unused, kept for call-site compat

    private var dropSize: CGFloat {
        // Map old fontSize to a reasonable drop size
        fontSize * 1.2
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breathe = 0.5 + 0.5 * sin(t * 0.7) // slow breathing

            // Rotate the gradient hue slowly
            let hueShift = Angle(degrees: t * 15) // ~24s full cycle

            ZStack {
                // Outer chromatic glow — breathes
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
                            center: .center,
                            startAngle: hueShift,
                            endAngle: hueShift + .degrees(360)
                        )
                    )
                    .frame(width: dropSize, height: dropSize * 1.25)
                    .blur(radius: 6 + breathe * 4)
                    .opacity(0.6 + breathe * 0.3)

                // Main droplet — iridescent fill
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
                            center: .center,
                            startAngle: hueShift,
                            endAngle: hueShift + .degrees(360)
                        )
                    )
                    .frame(width: dropSize, height: dropSize * 1.25)
                    .overlay(
                        // White specular highlight — upper left
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
        }
        .frame(maxWidth: .infinity)
    }
}
