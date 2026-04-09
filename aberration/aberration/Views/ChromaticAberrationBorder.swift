import SwiftUI

/// A border effect that mimics chromatic aberration — the RGB channel
/// splitting you see at the edges of a lens. Three colored strokes
/// (red, green, blue) are each slightly offset, creating
/// that prismatic rainbow fringe around the container.
///
/// Performance: no blur or shadow — just offset colored strokes with
/// opacity. Visually similar but dramatically cheaper.
///
/// `phase` (0...1) rotates the offset direction over time.
/// `intensity` (0...1) controls overall visibility — 0 hides the effect.
struct ChromaticAberrationBorder: View {
    let cornerRadius: CGFloat
    let phase: Double      // 0...1, drives rotation of offsets
    let intensity: Double   // 0...1, overall brightness

    // How far each color channel offsets from center (in points)
    private let maxOffset: CGFloat = 3.0
    private let strokeWidth: CGFloat = 2.5

    var body: some View {
        if intensity > 0 {
            ZStack {
                // Red channel — offset at phase angle 0°
                channelStroke(
                    color: Color(red: 1.0, green: 0.15, blue: 0.2),
                    angleOffset: 0
                )

                // Green channel — offset at phase angle 120°
                channelStroke(
                    color: Color(red: 0.2, green: 1.0, blue: 0.3),
                    angleOffset: 2 * .pi / 3
                )

                // Blue channel — offset at phase angle 240°
                channelStroke(
                    color: Color(red: 0.2, green: 0.3, blue: 1.0),
                    angleOffset: 4 * .pi / 3
                )

                // White core stroke for sharp edge definition
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.white.opacity(0.3 * intensity), lineWidth: 0.5)
            }
            .compositingGroup()
            .blendMode(.plusLighter)
        }
    }

    private func channelStroke(color: Color, angleOffset: Double) -> some View {
        let angle = phase * 2 * .pi + angleOffset
        let dx = cos(angle) * maxOffset * intensity
        let dy = sin(angle) * maxOffset * intensity

        return RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(color.opacity(0.6 * intensity), lineWidth: strokeWidth)
            .offset(x: dx, y: dy)
    }
}

#Preview {
    ZStack {
        Color(white: 0.95)
            .ignoresSafeArea()

        RoundedRectangle(cornerRadius: 20)
            .fill(.white)
            .frame(width: 300, height: 400)
            .overlay(
                ChromaticAberrationBorder(
                    cornerRadius: 20,
                    phase: 0.25,
                    intensity: 1.0
                )
            )
    }
}
