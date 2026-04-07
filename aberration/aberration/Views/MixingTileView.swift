//
//  MixingTileView.swift
//  aberration
//
//  Premium lava lamp mixing tile — fracture, dissolve, merge.
//
//  Over ~50 seconds:
//  1. Two colors enter as large masses from opposite sides
//  2. Masses fracture into many fragments that cross the center
//  3. A slow vortex swirls everything together
//  4. Fragments from both colors physically overlap and interleave
//  5. Tendrils stretch between blobs as they pull apart
//  6. Colors imperceptibly shift toward result — no hard transition
//  7. Caustic light dances on the fluid surface
//  8. By the end it's one unified color, indistinguishable
//

import SwiftUI

struct MixingTileView: View {
    let tile: MixingTile
    let size: CGFloat

    private let cornerRadius: CGFloat = 12

    // MARK: - Per-tile deterministic RNG

    private var seed: UInt64 {
        var hasher = Hasher()
        hasher.combine(tile.id)
        let hash = hasher.finalize()
        return UInt64(bitPattern: Int64(hash))
    }

    private func rand(_ offset: Int) -> Double {
        let mixed = seed &+ UInt64(offset) &* 2654435761
        return Double(mixed % 10000) / 10000.0
    }

    // MARK: - Body

    var body: some View {
        if tile.startDate == nil {
            emptyGlass
        } else {
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(tile.startDate ?? timeline.date)
                let progress = min(elapsed / tile.swirlDuration, 1.0)
                liquidGlass(elapsed: elapsed, progress: progress)
            }
        }
    }

    // MARK: - Empty glass

    private var emptyGlass: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xF0F0F4).opacity(0.6),
                            Color(hex: 0xE8E8ED).opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color(hex: 0xCCCCD4).opacity(0.5),
                              style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .frame(width: size, height: size)
    }

    // MARK: - Liquid Glass Container

    private func liquidGlass(elapsed: Double, progress: Double) -> some View {
        let fillLevel = min(elapsed / 0.8, 1.0)
        let settle = settleEase(progress)

        // Slow vortex rotation — everything swirls together
        let vortexAngle = elapsed * 0.08 + rand(900) * 6.28

        return ZStack {
            // Glass background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xF2F2F6), Color(hex: 0xE6E6EB)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Inner color bloom — grows as mixing progresses
            RadialGradient(
                colors: [
                    tile.resultColor.opacity(0.35 * fillLevel * (0.3 + progress * 0.7)),
                    tile.resultColor.opacity(0.12 * fillLevel),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: size * 0.7
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // === The fluid ===
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let fillH = h * fillLevel

                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        // Color A — fractures and crosses into B's territory
                        fluidLayer(
                            color: tile.colorA,
                            progress: progress,
                            elapsed: elapsed,
                            vortex: vortexAngle,
                            width: w,
                            height: fillH,
                            seedOffset: 0,
                            originX: 0.2,
                            blurRadius: w * 0.15
                        )

                        // Color B — fractures and crosses into A's territory
                        fluidLayer(
                            color: tile.colorB,
                            progress: progress,
                            elapsed: elapsed,
                            vortex: vortexAngle,
                            width: w,
                            height: fillH,
                            seedOffset: 300,
                            originX: 0.8,
                            blurRadius: w * 0.15
                        )

                        // Bubbles
                        if progress < 0.92 {
                            bubbleLayer(elapsed: elapsed, width: w, height: fillH)
                                .opacity((1.0 - settle) * 0.8)
                        }

                        // Caustic light ripples on the fluid surface
                        if fillLevel > 0.5 && progress < 0.95 {
                            causticLayer(elapsed: elapsed, width: w, height: fillH)
                                .opacity(0.12 * (1.0 - settle))
                        }

                        // Result color fills in — ultra-gradual, never jolts
                        Rectangle()
                            .fill(tile.resultColor)
                            .opacity(settle)
                    }
                    .frame(height: fillH)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // Inner shadow at edges — gives depth to the glass
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    .black.opacity(0.06 * fillLevel),
                    lineWidth: 3
                )
                .blur(radius: 2)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // Settled shimmer
            if progress >= 1.0 {
                settledShimmer(elapsed: elapsed)
            }

            // Glass specular
            LinearGradient(
                colors: [
                    .white.opacity(0.38),
                    .white.opacity(0.10),
                    .white.opacity(0.02),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // Top edge catch
            VStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.22), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: 10)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            // Glass border
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.2), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
        .shadow(color: tile.resultColor.opacity(0.18 * fillLevel), radius: 8, y: 3)
        .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
        .frame(width: size, height: size)
    }

    // MARK: - Fluid Layer (fracture + dissolve + merge)
    //
    // Starts as 2 parent blobs → fractures into up to 12 fragments.
    // Fragments cross past center into the other color's territory.
    // A slow vortex swirls everything. Tendrils stretch between
    // separating blobs. Color gradually becomes the result.

    private func fluidLayer(
        color: Color,
        progress: Double,
        elapsed: Double,
        vortex: Double,
        width: CGFloat,
        height: CGFloat,
        seedOffset: Int,
        originX: CGFloat,
        blurRadius: CGFloat
    ) -> some View {
        // Fragment count ramps: 2 → 12 over the duration
        let maxFragments = 12
        let fragmentCount = 2 + Int(min(progress * 1.5, 1.0) * Double(maxFragments - 2))

        // How far past center fragments can travel (goes beyond 0.5!)
        let driftStrength = progress * progress  // accelerates
        let centerDrift = driftStrength * (0.5 - originX)
        let overshoot = max(0, progress - 0.3) * 0.4 * (0.5 - originX).sign  // cross past center

        // Color dissolve: gradual shift original → result
        let colorT = settleEase(progress)

        return Canvas { context, canvasSize in
            // Interpolate threshold color from original toward result
            // At low colorT → original color. At high colorT → result.
            let threshColor = colorT < 0.4 ? color : tile.resultColor
            context.addFilter(.alphaThreshold(min: 0.28, color: threshColor))
            context.addFilter(.blur(radius: blurRadius))

            context.drawLayer { ctx in
                for i in 0..<fragmentCount {
                    let r0 = rand(seedOffset + i * 11 + 1)
                    let r1 = rand(seedOffset + i * 11 + 2)
                    let r2 = rand(seedOffset + i * 11 + 3)
                    let r3 = rand(seedOffset + i * 11 + 4)
                    let r4 = rand(seedOffset + i * 11 + 5)
                    let r5 = rand(seedOffset + i * 11 + 6)
                    let r6 = rand(seedOffset + i * 11 + 7)
                    let r7 = rand(seedOffset + i * 11 + 8)
                    let r8 = rand(seedOffset + i * 11 + 9)

                    let isParent = i < 2

                    // ── Size ──
                    let baseSize: Double
                    if isParent {
                        // Parents shrink as they shed fragments
                        baseSize = 0.42 - progress * 0.22
                    } else {
                        // Fragments fade in based on when they "spawn"
                        let spawnProgress = Double(i - 2) / Double(maxFragments - 2)
                        let age = max(0, progress - spawnProgress * 0.5)
                        // Small at birth, grows, then shrinks as it dissolves
                        let growPhase = min(age / 0.3, 1.0)
                        let dissolvePhase = max(0, (progress - 0.7) / 0.3)
                        baseSize = (0.1 + r0 * 0.12) * growPhase * (1.0 - dissolvePhase * 0.5)
                    }

                    let pulse = 0.05 * sin(elapsed * (0.25 + r1 * 0.35) + r2 * 6.28)
                    let blobDiameter = width * max(0.04, baseSize + pulse)

                    // ── Position with vortex ──
                    // Each fragment has a "home" position that drifts toward
                    // (and past) center. The vortex rotates it around center.
                    let homeX: Double
                    let homeY: Double

                    if isParent {
                        homeX = originX + centerDrift * 0.6
                        homeY = i == 0 ? 0.33 : 0.67
                    } else {
                        // Fragments spread across the tile, crossing center
                        let spreadX = originX + centerDrift + overshoot * (0.3 + r3 * 0.7)
                        homeX = max(0.05, min(0.95, spreadX + (r4 - 0.5) * 0.3 * progress))
                        homeY = 0.08 + r7 * 0.84
                    }

                    // Vortex rotation around center
                    let vortexStrength = progress * 0.15  // how much rotation affects position
                    let dx = homeX - 0.5
                    let dy = homeY - 0.5
                    let dist = sqrt(dx * dx + dy * dy)
                    let angle = atan2(dy, dx) + vortex * (1.0 + r8 * 0.5) * vortexStrength
                    let vortexX = 0.5 + dist * cos(angle)
                    let vortexY = 0.5 + dist * sin(angle)

                    // Organic wobble on top
                    let freqX = 0.2 + r3 * 0.4
                    let freqY = 0.15 + r4 * 0.35
                    let phase = r5 * 6.28
                    let wobbleAmp = isParent ? 0.06 : (0.1 + r6 * 0.06)
                    let wobbleX = wobbleAmp * sin(elapsed * freqX + phase + Double(i) * 0.9)
                    let wobbleY = wobbleAmp * cos(elapsed * freqY + phase * 1.3 + Double(i) * 0.6)

                    let finalX = (vortexX + wobbleX) * width
                    let finalY = (vortexY + wobbleY) * height

                    // ── Organic stretch (tendrils when separating) ──
                    // More stretch = more elongated = tendril-like
                    let stretchBase = 1.0 + progress * 0.15  // everything gets a bit more organic
                    let stretchX = stretchBase + 0.25 * sin(elapsed * (0.18 + r2 * 0.15) + phase)
                    let stretchY = stretchBase + 0.2 * cos(elapsed * (0.22 + r4 * 0.12) + phase * 0.7)

                    let rect = CGRect(
                        x: finalX - blobDiameter * stretchX / 2,
                        y: finalY - blobDiameter * stretchY / 2,
                        width: blobDiameter * stretchX,
                        height: blobDiameter * stretchY
                    )
                    ctx.fill(Path(ellipseIn: rect), with: .color(.white))

                    // ── Tendril: small bridge blob between this and a neighbor ──
                    // Creates the "stretching" look when blobs pull apart
                    if i > 0 && i < fragmentCount - 1 && !isParent {
                        let neighborSeed = seedOffset + (i - 1) * 11
                        let nr7 = rand(neighborSeed + 8)
                        let neighborY = 0.08 + nr7 * 0.84
                        // Tendril midpoint between this blob and its neighbor
                        let tendrilX = finalX + wobbleX * width * 0.3
                        let tendrilY = (finalY + neighborY * height) / 2
                        let tendrilSize = blobDiameter * 0.35
                        let tRect = CGRect(
                            x: tendrilX - tendrilSize / 2,
                            y: tendrilY - tendrilSize / 2,
                            width: tendrilSize,
                            height: tendrilSize * 1.8  // tall and thin
                        )
                        ctx.fill(Path(ellipseIn: tRect), with: .color(.white))
                    }
                }
            }
        }
        // Blobs stay visible almost to the end — only fully gone when settle ≈ 1
        .opacity(max(0, 1.0 - colorT * 1.1))
        .allowsHitTesting(false)
    }

    // MARK: - Caustic Light

    /// Simulates light refracting through liquid — dancing bright spots
    private func causticLayer(elapsed: Double, width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, _ in
            for i in 0..<4 {
                let r0 = rand(600 + i * 4)
                let r1 = rand(601 + i * 4)
                let r2 = rand(602 + i * 4)
                let r3 = rand(603 + i * 4)

                let x = (0.15 + r0 * 0.7 + 0.1 * sin(elapsed * (0.3 + r1 * 0.2))) * width
                let y = (0.1 + r2 * 0.5 + 0.08 * cos(elapsed * (0.25 + r3 * 0.15))) * height
                let sz = (8.0 + r1 * 12.0) * (0.7 + 0.3 * sin(elapsed * 0.4 + r0 * 6.28))
                let opacity = 0.4 + 0.3 * sin(elapsed * (0.5 + r2 * 0.3) + r3 * 6.28)

                let rect = CGRect(x: x - sz / 2, y: y - sz / 2, width: sz, height: sz * 0.6)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
            }
        }
        .blur(radius: 4)
        .allowsHitTesting(false)
    }

    // MARK: - Bubbles

    private func bubbleLayer(elapsed: Double, width: CGFloat, height: CGFloat) -> some View {
        Canvas { context, _ in
            for i in 0..<8 {
                let r0 = rand(400 + i * 3)
                let r1 = rand(401 + i * 3)
                let r2 = rand(402 + i * 3)

                let period = 3.0 + r0 * 3.0  // 3–6s per rise
                let phase = r1 * period
                let t = ((elapsed + phase).truncatingRemainder(dividingBy: period)) / period

                let x = (0.1 + r2 * 0.8) * width + 2.0 * sin(elapsed * 1.2 + Double(i))
                let y = height * (1.0 - t)
                let sz: CGFloat = 1.0 + CGFloat(r0) * 2.0
                let opacity = 0.18 * (1.0 - abs(t - 0.5) * 2)

                let rect = CGRect(x: x - sz / 2, y: y - sz / 2, width: sz, height: sz)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Settled Shimmer

    private func settledShimmer(elapsed: Double) -> some View {
        let shimmerX = 0.3 + 0.4 * sin(elapsed * 0.3 + rand(500) * 6.28)
        let shimmerOpacity = 0.07 + 0.04 * sin(elapsed * 0.5 + rand(501) * 6.28)

        return RadialGradient(
            colors: [.white.opacity(shimmerOpacity), .clear],
            center: UnitPoint(x: shimmerX, y: 0.3),
            startRadius: 0,
            endRadius: size * 0.6
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .allowsHitTesting(false)
    }

    // MARK: - Settle Curve

    /// Ultra-slow power curve. Barely perceptible for the first half,
    /// then gently accelerates. By 80% through, colors are nearly
    /// indistinguishable. By 100% it's perfectly uniform.
    private func settleEase(_ progress: Double) -> Double {
        guard progress > 0.03 else { return 0 }
        let t = (progress - 0.03) / 0.97
        // x⁴ — even slower start than cubic, smoother dissolve
        return t * t * t * t
    }
}

// Helper for sign of a Double
private extension Double {
    var sign: Double { self >= 0 ? 1.0 : -1.0 }
}
