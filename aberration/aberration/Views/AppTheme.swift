//
//  AppTheme.swift
//  aberration
//
//  Centralized dark mode support.
//  Every semantic color adapts based on the global isDarkMode flag.
//  Tile/game colors remain unchanged — only UI chrome adapts.
//

import SwiftUI

@Observable
final class AppTheme {
    static let shared = AppTheme()

    /// Persisted across launches
    var isDark: Bool {
        didSet { UserDefaults.standard.set(isDark, forKey: "isDarkMode") }
    }

    private init() {
        self.isDark = UserDefaults.standard.bool(forKey: "isDarkMode")
    }

    // MARK: - Backgrounds

    /// Full-screen background — true black base like premium dark UIs
    var screenBgTop: Color { isDark ? Color(hex: 0x000000) : Color(hex: 0xF5F5F7) }
    var screenBgBottom: Color { isDark ? Color(hex: 0x050506) : Color(hex: 0xF5F5F7) }
    /// Flat fallback (non-gradient contexts)
    var screenBg: Color { isDark ? Color(hex: 0x000000) : Color(hex: 0xF5F5F7) }

    /// Glass card fill — neutral dark gray, lifted off true-black bg
    var cardFill: Color { isDark ? Color(hex: 0x1C1C1E) : .white }
    var cardFillOpacity: Double { isDark ? 0.82 : 0.88 }
    var cardMaterial: Material { isDark ? .ultraThinMaterial : .thinMaterial }
    var cardBorderOpacity: Double { isDark ? 0.06 : 0.9 }
    var cardBorderColor: Color { isDark ? .white : .white }

    /// Settings background
    var settingsBg: Color { isDark ? Color(hex: 0x000000) : Color(hex: 0xF5F5F7) }

    // MARK: - Text — 3-tier contrast hierarchy

    /// Primary text (scores, hero numbers) — bright white in dark
    var textPrimary: Color { isDark ? Color(hex: 0xFFFFFF) : Color(hex: 0x2A2A2A) }
    var textPrimaryAlt: Color { isDark ? Color(hex: 0xF0F2F5) : Color(hex: 0x3A3A4A) }

    /// Secondary text (labels, subtitles) — neutral mid-tone
    var textSecondary: Color { isDark ? Color(hex: 0x9A9A9E) : Color(hex: 0x888888) }

    /// Tertiary text (hints, faint labels) — recedes into bg
    var textTertiary: Color { isDark ? Color(hex: 0x58585C) : Color(hex: 0xAAAAAA) }
    var textQuaternary: Color { isDark ? Color(hex: 0x3A3A3E) : Color(hex: 0xCCCCCC) }

    /// Muted body text
    var textMuted: Color { isDark ? Color(hex: 0x78787E) : Color(hex: 0x999999) }

    /// Stat values
    var statValue: Color { isDark ? Color(hex: 0xDADADE) : Color(hex: 0x4A4A5A) }

    /// Score large number — full white for maximum pop
    var scoreLarge: Color { isDark ? Color(hex: 0xFFFFFF) : Color(hex: 0x2A2A3A) }

    // MARK: - Grid / Cells

    /// Empty cell fill — neutral dark wells, subtle depth
    var emptyCellTop: Color { isDark ? Color(hex: 0x161618) : Color(hex: 0xEAEAEE) }
    var emptyCellBottom: Color { isDark ? Color(hex: 0x111113) : Color(hex: 0xE0E0E5) }
    var emptyCellBorder: Color { isDark ? Color(hex: 0x2A2A2E) : Color(hex: 0xD0D0D8) }
    var emptyCellShadowOpacity: Double { isDark ? 0.25 : 0.04 }
    /// Faint inner glow for dark empty cells
    var emptyCellInnerGlow: Color { isDark ? Color(hex: 0xFFFFFF) : .clear }
    var emptyCellInnerGlowOpacity: Double { isDark ? 0.02 : 0.0 }

    /// Colored bloom around filled tiles in dark mode
    var tileGlowRadius: CGFloat { isDark ? 10 : 0 }
    var tileGlowOpacity: Double { isDark ? 0.4 : 0.0 }

    // MARK: - Mixing Lane

    /// Empty glass in mixing lane
    var mixGlassTop: Color { isDark ? Color(hex: 0x18181A) : Color(hex: 0xF0F0F4) }
    var mixGlassBottom: Color { isDark ? Color(hex: 0x121214) : Color(hex: 0xE8E8ED) }
    var mixGlassDash: Color { isDark ? Color(hex: 0x333336) : Color(hex: 0xCCCCD4) }

    /// Mixing tile glass background
    var mixTileBgTop: Color { isDark ? Color(hex: 0x1A1A1C) : Color(hex: 0xF2F2F6) }
    var mixTileBgBottom: Color { isDark ? Color(hex: 0x141416) : Color(hex: 0xE6E6EB) }

    // MARK: - Dividers / Separators

    var divider: Color { isDark ? Color(hex: 0x2A2A2E) : Color(hex: 0xDDDDDD) }
    var dividerOpacity: Double { isDark ? 0.5 : 0.5 }

    // MARK: - Overlays

    /// Overlay card background
    var overlayCardFill: Color { isDark ? Color(hex: 0x1C1C1E) : .white }
    var overlayCardOpacity: Double { isDark ? 0.97 : 0.9 }
    var overlayBgDim: Double { isDark ? 0.6 : 0.3 }

    // MARK: - Buttons

    /// Primary button (dark pill) — inverted for dark mode
    var primaryButtonBg: Color { isDark ? Color(hex: 0xF0F0F2) : Color(hex: 0x2A2A2A) }
    var primaryButtonText: Color { isDark ? Color(hex: 0x000000) : .white }

    /// Secondary button
    var secondaryButtonBg: Color { isDark ? Color(hex: 0x1C1C1E) : .white }
    var secondaryButtonBgOpacity: Double { isDark ? 0.9 : 0.8 }
    var secondaryButtonBorder: Color { isDark ? Color(hex: 0x3A3A3E) : Color(hex: 0x2A2A2A) }

    /// Icon button color
    var iconDefault: Color { isDark ? Color(hex: 0xB0B0B4) : Color(hex: 0x4A4A4A) }
    var iconMuted: Color { isDark ? Color(hex: 0x68686E) : Color(hex: 0x555555) }

    // MARK: - Shadows

    var shadowOpacity: Double { isDark ? 0.3 : 0.06 }

    // MARK: - Navigation bar

    var navBarBg: Material { isDark ? .ultraThinMaterial : .ultraThinMaterial }
    var navBarDivider: Color { isDark ? Color(hex: 0x1A1A1C) : Color(hex: 0xDDDDDD) }
    /// Inactive nav icon — very dim in dark mode so game stays focal
    var navIconInactive: Color { isDark ? Color(hex: 0x48484E) : Color(hex: 0xAAAAAA) }
    /// Active nav icon — brighter
    var navIconActive: Color { isDark ? Color(hex: 0xD0D0D4) : Color(hex: 0x3A3A4A) }

    // MARK: - Toast

    var toastFill: Color { isDark ? Color(hex: 0x1C1C1E) : .white }
    var toastFillOpacity: Double { isDark ? 0.94 : 0.85 }
    var toastText: Color { isDark ? Color(hex: 0xF0F0F2) : Color(hex: 0x3A3A4A) }

    // MARK: - Dot grid

    var dotGridColor: Color { isDark ? .white : .black }
    var dotGridOpacity: Double { isDark ? 0.03 : 0.08 }

    // MARK: - Tunnel background dots

    var tunnelDotBrightness: CGFloat { isDark ? 0.45 : 0.35 }

    // MARK: - Achievement toast bg
    var achievementToastBg: Color { isDark ? Color(hex: 0x1C1C1E) : .white }
    var achievementToastBgOpacity: Double { isDark ? 0.97 : 0.95 }

    // MARK: - Empty states / locked items
    var lockedBgTop: Color { isDark ? Color(hex: 0x1A1A1C) : Color(hex: 0xEDEDEF) }
    var lockedBgBottom: Color { isDark ? Color(hex: 0x141416) : Color(hex: 0xE0E0E2) }

    // MARK: - Specular / glass highlights
    var specularOpacity: Double { isDark ? 0.12 : 0.4 }
    var topEdgeCatchOpacity: Double { isDark ? 0.08 : 0.25 }
    var glassBorderStartOpacity: Double { isDark ? 0.12 : 0.5 }
    var glassBorderEndOpacity: Double { isDark ? 0.03 : 0.1 }

    // MARK: - Hint pill
    var hintActiveBg: Color { isDark ? Color(hex: 0x5A9BC7).opacity(0.2) : Color(hex: 0x5A9BC7).opacity(0.15) }
    var hintInactiveBg: Color { isDark ? Color(hex: 0x1C1C1E) : Color(hex: 0xDDDDE2) }
}
