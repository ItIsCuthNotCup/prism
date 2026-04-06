//
//  IridescentTheme.swift
//  aberration
//
//  Calm, modern iridescent design system.
//  Frosted glass with pearlescent sheen — luminous, never loud.
//

import SwiftUI

// MARK: - Iridescent Color Palette

enum Iridescent {
    // Core background — warm pearl instead of flat grey
    static let backgroundTop    = Color(hex: 0xF7F6FA)   // faint lavender tint
    static let backgroundBottom = Color(hex: 0xF2F0F0)   // warm neutral

    // Pearlescent accent colors (always used at low opacity)
    static let cyan   = Color(hex: 0x7EC8E3)
    static let violet = Color(hex: 0xB8A0E0)
    static let gold   = Color(hex: 0xE0D0A0)
    static let rose   = Color(hex: 0xE0A0B8)

    // Card surface
    static let cardFill     = Color.white.opacity(0.78)
    static let cardBorder   = Color.white.opacity(0.6)

    // Shadow tint (violet-tinted instead of pure black)
    static let shadowColor = Color(hex: 0x8878A8).opacity(0.12)
    static let shadowLight = Color(hex: 0x8878A8).opacity(0.08)

    // Empty cell pearl tint
    static let cellTop    = Color(hex: 0xE8E6F0)  // visible lavender
    static let cellBottom = Color(hex: 0xE2E0EC)
    static let cellBorder = Color(hex: 0xCEC8DA)

    // Shared border gradient — the signature iridescent sheen
    static func borderGradient(
        startAngle: Double = -60,
        endAngle: Double = 300,
        intensity: Double = 1.0
    ) -> AngularGradient {
        AngularGradient(
            colors: [
                cyan.opacity(0.40 * intensity),
                violet.opacity(0.35 * intensity),
                gold.opacity(0.25 * intensity),
                rose.opacity(0.30 * intensity),
                cyan.opacity(0.40 * intensity)
            ],
            center: .center,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle)
        )
    }

    // Lighter variant for smaller cards
    static func borderGradientLight(
        startAngle: Double = 0,
        endAngle: Double = 360,
        intensity: Double = 0.7
    ) -> AngularGradient {
        borderGradient(startAngle: startAngle, endAngle: endAngle, intensity: intensity)
    }

    // Nav bar divider gradient
    static var navDividerGradient: LinearGradient {
        LinearGradient(
            colors: [
                cyan.opacity(0.3),
                violet.opacity(0.35),
                gold.opacity(0.25),
                rose.opacity(0.3),
                cyan.opacity(0.3)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Iridescent Background

/// Full-screen background with subtle shifting color wash.
struct IridescentBackground: View {
    var body: some View {
        ZStack {
            // Base
            LinearGradient(
                colors: [Iridescent.backgroundTop, Iridescent.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            // Top-left cyan wash
            RadialGradient(
                colors: [Iridescent.cyan.opacity(0.09), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )

            // Bottom-right violet wash
            RadialGradient(
                colors: [Iridescent.violet.opacity(0.08), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 400
            )

            // Center-bottom gold warmth
            RadialGradient(
                colors: [Iridescent.gold.opacity(0.05), .clear],
                center: UnitPoint(x: 0.5, y: 0.85),
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Pearlescent Card

/// Glass card with iridescent border sheen — the main game card.
struct PearlescentCard: View {
    var cornerRadius: CGFloat = 20

    var body: some View {
        ZStack {
            // Frosted glass fill
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Iridescent.cardFill)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.thinMaterial)

            // Soft glow layer (blurred, behind the crisp border)
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    Iridescent.borderGradient(intensity: 0.6),
                    lineWidth: 4
                )
                .blur(radius: 3)

            // Crisp iridescent border — the signature detail
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    Iridescent.borderGradient(),
                    lineWidth: 1.5
                )

            // Inner highlight — top edge light catch
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1), .clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: Iridescent.shadowColor, radius: 16, y: 6)
    }
}

// MARK: - Pearlescent Menu Card (for start screen cards)

struct PearlescentMenuCard: View {
    var cornerRadius: CGFloat = 16

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.82))
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.thinMaterial)

            // Soft glow
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    Iridescent.borderGradientLight(intensity: 0.5),
                    lineWidth: 3
                )
                .blur(radius: 2.5)

            // Crisp border
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    Iridescent.borderGradientLight(),
                    lineWidth: 1
                )
        }
        .shadow(color: Iridescent.shadowLight, radius: 12, y: 4)
    }
}

// MARK: - Iridescent Dot Grid

/// Dot grid with faint color variation — dots subtly shift between pearl tones.
struct IridescentDotGrid: View {
    var body: some View {
        Canvas { context, size in
            let dotSpacing: CGFloat = 20
            let dotRadius: CGFloat = 0.7
            let cols = Int(size.width / dotSpacing)
            let rows = Int(size.height / dotSpacing)

            for col in 0...cols {
                for row in 0...rows {
                    let x = CGFloat(col) * dotSpacing
                    let y = CGFloat(row) * dotSpacing
                    let rect = CGRect(
                        x: x - dotRadius,
                        y: y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )

                    // Subtle color variation based on position
                    let hue = (Double(col + row) * 0.02).truncatingRemainder(dividingBy: 1.0)
                    let color = Color(
                        hue: hue * 0.15 + 0.6,  // range: blue-violet-cyan
                        saturation: 0.18,
                        brightness: 0.68
                    ).opacity(0.14)

                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Pearlescent Overlay Card (for overlays like game over, solved, etc.)

struct PearlescentOverlayCard: View {
    var cornerRadius: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.white.opacity(0.85))
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)

            // Soft outer glow
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    Iridescent.borderGradient(startAngle: -90, endAngle: 270, intensity: 0.5),
                    lineWidth: 5
                )
                .blur(radius: 4)

            // Crisp iridescent edge
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    Iridescent.borderGradient(startAngle: -90, endAngle: 270),
                    lineWidth: 1.5
                )

            // Top edge catch
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: Iridescent.shadowColor, radius: 24, y: 10)
    }
}

// MARK: - Stats/Settings Card

struct PearlescentSettingsCard: View {
    var cornerRadius: CGFloat = 16

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.white.opacity(0.82))
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.thinMaterial)

            // Soft glow
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    Iridescent.borderGradientLight(intensity: 0.45),
                    lineWidth: 3
                )
                .blur(radius: 2)

            // Crisp border
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    Iridescent.borderGradientLight(),
                    lineWidth: 0.75
                )
        }
        .shadow(color: Iridescent.shadowLight, radius: 12, y: 4)
    }
}
