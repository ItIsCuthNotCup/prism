//
//  RoundAnnouncerView.swift
//  aberration
//
//  Slot-machine reel effect for announcing rounds and target colors.
//  Text scrolls vertically through a masked window with blurred edges,
//  pauses in the clear center, then scrolls away and disappears.
//  The center line flashes in the target color with a fast alternating effect.
//

import SwiftUI

/// Displays a slot-machine-style reel that announces the round number
/// and target color name, then auto-dismisses.
struct RoundAnnouncerView: View {
    let round: Int
    let colorName: String
    let targetColor: Color
    let onComplete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isVisible = true
    @State private var colorFlashOn = false

    // Layout
    private let windowHeight: CGFloat = 160
    private let lineHeight: CGFloat = 26
    private let lineCount = 7  // repeated lines visible at once

    var body: some View {
        if isVisible {
            HStack(spacing: 0) {
                // Round number reel — left side
                reelColumn(text: "Round \(round)", alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 90)  // space for the sphere in the center

                // Color name reel — right side
                reelColumn(text: colorName, alignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .frame(height: windowHeight)
            .allowsHitTesting(false)
            .onAppear {
                startAnimation()
                startColorFlash()
            }
        }
    }

    private func reelColumn(text: String, alignment: HorizontalAlignment) -> some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ForEach(0..<lineCount * 2, id: \.self) { i in
                    let isCenterLine = isCenterIndex(i)
                    let baseColor: Color = AppTheme.shared.isDark ? .white : Color(hex: 0x2A2A3A)
                    Text(text)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(isCenterLine && colorFlashOn ? targetColor : baseColor)
                        .shadow(color: isCenterLine && colorFlashOn ? targetColor.opacity(0.6) : .clear, radius: 8)
                        .frame(height: lineHeight)
                        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
                }
            }
            .offset(y: offset)
            .frame(width: geo.size.width, height: windowHeight, alignment: .top)
            .clipped()
            .mask(
                // Gradient mask: heavy fade at top (under score), lighter at bottom
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .clear, location: 0.1),
                        .init(color: .white.opacity(0.3), location: 0.25),
                        .init(color: .white, location: 0.4),
                        .init(color: .white, location: 0.7),
                        .init(color: .clear, location: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(height: windowHeight)
    }

    /// Check if a given line index is roughly the center line
    /// (the one that should flash with target color)
    private func isCenterIndex(_ i: Int) -> Bool {
        // Center of the reel = lineCount (middle of the doubled array)
        let center = lineCount
        return i >= center - 1 && i <= center + 1
    }

    private func startColorFlash() {
        // Fast alternating flash — toggles rapidly during spin, then stays on when settled
        Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { timer in
            if !isVisible {
                timer.invalidate()
                return
            }
            colorFlashOn.toggle()
        }
    }

    private func startAnimation() {
        let totalTravel = lineHeight * CGFloat(lineCount)

        // Start above — text enters from top
        offset = lineHeight * 2

        // Phase 1: Scroll into view (fast reel spin)
        withAnimation(.easeOut(duration: 0.5)) {
            offset = -lineHeight * CGFloat(lineCount / 2) + windowHeight / 2 - lineHeight / 2
        }

        // Phase 2: Hold in clear zone for ~1.2 seconds, then scroll out
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            withAnimation(.easeIn(duration: 0.4)) {
                offset = -totalTravel - lineHeight * 2
            }
        }

        // Phase 3: Remove from view
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            isVisible = false
            onComplete()
        }
    }
}
