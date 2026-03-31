//
//  ShareImageRenderer.swift
//  Chromatose
//
//  Generates a shareable score card image (1080x1920) for
//  Instagram Stories, Facebook, Twitter, etc.
//

import UIKit

struct ShareImageRenderer {

    static func render(
        score: Int,
        round: Int,
        highScore: Int,
        totalBlends: Int,
        isNewRecord: Bool
    ) -> UIImage {
        let w: CGFloat = 1080
        let h: CGFloat = 1920
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))

        return renderer.image { ctx in
            let cg = ctx.cgContext

            // — Background —
            UIColor(white: 0.96, alpha: 1).setFill()
            cg.fill(CGRect(x: 0, y: 0, width: w, height: h))

            // Draw a pattern of colored dots (like the game background)
            let palette = randomSharePalette()
            let spacing: CGFloat = 48
            let dotR: CGFloat = 8

            for gx in stride(from: spacing * 0.5, to: w, by: spacing) {
                for gy in stride(from: spacing * 0.5, to: h, by: spacing) {
                    for (i, color) in palette.enumerated() {
                        let angle = CGFloat(i) * .pi * 2 / CGFloat(palette.count)
                        let sep: CGFloat = 14
                        let sx = gx + cos(angle) * sep
                        let sy = gy + sin(angle) * sep
                        color.withAlphaComponent(0.5).setFill()
                        cg.fillEllipse(in: CGRect(x: sx - dotR, y: sy - dotR,
                                                   width: dotR * 2, height: dotR * 2))
                    }
                }
            }

            // — Central card —
            let cardW: CGFloat = 880
            let cardH: CGFloat = 1000
            let cardX = (w - cardW) / 2
            let cardY: CGFloat = 420
            let cardRect = CGRect(x: cardX, y: cardY, width: cardW, height: cardH)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 48)

            // Card shadow
            cg.saveGState()
            cg.setShadow(offset: CGSize(width: 0, height: 12), blur: 40,
                         color: UIColor.black.withAlphaComponent(0.1).cgColor)
            UIColor.white.withAlphaComponent(0.95).setFill()
            cardPath.fill()
            cg.restoreGState()

            // Card fill again (on top of shadow)
            UIColor.white.withAlphaComponent(0.95).setFill()
            cardPath.fill()

            // — "CHROMATOSE" title at top —
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 72, weight: .heavy),
                .foregroundColor: UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1),
                .kern: 4.0
            ]
            let titleStr = "CHROMATOSE" as NSString
            let titleSize = titleStr.size(withAttributes: titleAttrs)
            titleStr.draw(at: CGPoint(x: (w - titleSize.width) / 2, y: 220),
                         withAttributes: titleAttrs)

            // — Score (big number) —
            let scoreStr = "\(score)" as NSString
            let scoreAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 140, weight: .black),
                .foregroundColor: isNewRecord
                    ? UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1)
                    : UIColor(red: 0.23, green: 0.23, blue: 0.29, alpha: 1)
            ]
            let scoreSize = scoreStr.size(withAttributes: scoreAttrs)
            scoreStr.draw(at: CGPoint(x: (w - scoreSize.width) / 2, y: cardY + 80),
                         withAttributes: scoreAttrs)

            // "POINTS" label
            let pointsAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
                .foregroundColor: UIColor(white: 0.7, alpha: 1),
                .kern: 6.0
            ]
            let pointsStr = "POINTS" as NSString
            let pointsSize = pointsStr.size(withAttributes: pointsAttrs)
            pointsStr.draw(at: CGPoint(x: (w - pointsSize.width) / 2,
                                       y: cardY + 80 + scoreSize.height + 4),
                          withAttributes: pointsAttrs)

            // — NEW RECORD badge —
            if isNewRecord {
                let badgeAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .black),
                    .foregroundColor: UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1),
                    .kern: 4.0
                ]
                let badgeStr = "NEW RECORD" as NSString
                let badgeSize = badgeStr.size(withAttributes: badgeAttrs)
                let badgeX = (w - badgeSize.width - 32) / 2
                let badgeY = cardY + 40

                let badgeRect = CGRect(x: badgeX, y: badgeY,
                                       width: badgeSize.width + 32, height: badgeSize.height + 12)
                let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeRect.height / 2)
                UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 0.12).setFill()
                badgePath.fill()

                badgeStr.draw(at: CGPoint(x: badgeX + 16, y: badgeY + 6),
                             withAttributes: badgeAttrs)
            }

            // — Stats row —
            let statsY = cardY + 420
            let statFont = UIFont.systemFont(ofSize: 48, weight: .bold)
            let labelFont = UIFont.systemFont(ofSize: 22, weight: .medium)
            let statColor = UIColor(red: 0.23, green: 0.23, blue: 0.29, alpha: 1)
            let labelColor = UIColor(white: 0.7, alpha: 1)

            let stats: [(String, String)] = [
                ("ROUND", "\(round)"),
                ("BLENDS", "\(totalBlends)"),
                ("BEST", "\(highScore)")
            ]

            let statSpacing: CGFloat = cardW / CGFloat(stats.count)
            for (i, stat) in stats.enumerated() {
                let centerX = cardX + statSpacing * (CGFloat(i) + 0.5)

                let valAttrs: [NSAttributedString.Key: Any] = [
                    .font: statFont, .foregroundColor: statColor
                ]
                let valStr = stat.1 as NSString
                let valSize = valStr.size(withAttributes: valAttrs)
                valStr.draw(at: CGPoint(x: centerX - valSize.width / 2, y: statsY),
                           withAttributes: valAttrs)

                let labAttrs: [NSAttributedString.Key: Any] = [
                    .font: labelFont, .foregroundColor: labelColor, .kern: 2.0
                ]
                let labStr = stat.0 as NSString
                let labSize = labStr.size(withAttributes: labAttrs)
                labStr.draw(at: CGPoint(x: centerX - labSize.width / 2,
                                        y: statsY + valSize.height + 4),
                           withAttributes: labAttrs)
            }

            // — Divider line —
            let divY = statsY + 120
            cg.setStrokeColor(UIColor(white: 0.9, alpha: 1).cgColor)
            cg.setLineWidth(2)
            cg.move(to: CGPoint(x: cardX + 60, y: divY))
            cg.addLine(to: CGPoint(x: cardX + cardW - 60, y: divY))
            cg.strokePath()

            // — Tagline —
            let tagAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .medium),
                .foregroundColor: UIColor(white: 0.55, alpha: 1)
            ]
            let tagStr = "Blend colors. Match targets. Stay alive." as NSString
            let tagSize = tagStr.size(withAttributes: tagAttrs)
            tagStr.draw(at: CGPoint(x: (w - tagSize.width) / 2, y: divY + 40),
                       withAttributes: tagAttrs)

            // — Bottom CTA —
            let ctaAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30, weight: .bold),
                .foregroundColor: UIColor(white: 0.45, alpha: 1),
                .kern: 2.0
            ]
            let ctaStr = "Can you beat my score?" as NSString
            let ctaSize = ctaStr.size(withAttributes: ctaAttrs)
            ctaStr.draw(at: CGPoint(x: (w - ctaSize.width) / 2, y: h - 200),
                       withAttributes: ctaAttrs)

            // App name at very bottom
            let footAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor(white: 0.7, alpha: 1),
                .kern: 3.0
            ]
            let footStr = "CHROMATOSE" as NSString
            let footSize = footStr.size(withAttributes: footAttrs)
            footStr.draw(at: CGPoint(x: (w - footSize.width) / 2, y: h - 120),
                        withAttributes: footAttrs)
        }
    }

    // Random palette for the share image background
    private static func randomSharePalette() -> [UIColor] {
        let hue = CGFloat.random(in: 0...1)
        return [
            UIColor(hue: hue, saturation: 0.7, brightness: 0.9, alpha: 1),
            UIColor(hue: (hue + 0.33).truncatingRemainder(dividingBy: 1),
                    saturation: 0.7, brightness: 0.9, alpha: 1),
            UIColor(hue: (hue + 0.66).truncatingRemainder(dividingBy: 1),
                    saturation: 0.7, brightness: 0.9, alpha: 1)
        ]
    }
}
