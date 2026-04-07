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

    /// Full-screen background — dark uses a deep near-black
    var screenBgTop: Color { isDark ? Color(hex: 0x0E0F13) : Color(hex: 0xF5F5F7) }
    var screenBgBottom: Color { isDark ? Color(hex: 0x151821) : Color(hex: 0xF5F5F7) }
    /// Flat fallback (non-gradient contexts)
    var screenBg: Color { isDark ? Color(hex: 0x0F1014) : Color(hex: 0xF5F5F7) }

    /// Glass card fill — darker, more transparent in dark mode for depth
    var cardFill: Color { isDark ? Color(hex: 0x181A22) : .white }
    var cardFillOpacity: Double { isDark ? 0.78 : 0.88 }
    var cardMaterial: Material { isDark ? .ultraThinMaterial : .thinMaterial }
    var cardBorderOpacity: Double { isDark ? 0.08 : 0.9 }
    var cardBorderColor: Color { isDark ? .white : .white }

    /// Settings background
    var settingsBg: Color { isDark ? Color(hex: 0x0F1014) : Color(hex: 0xF5F5F7) }

    // MARK: - Text — 3-tier contrast hierarchy

    /// Primary text (scores, hero numbers) — bright white in dark
    var textPrimary: Color { isDark ? Color(hex: 0xFFFFFF) : Color(hex: 0x2A2A2A) }
    var textPrimaryAlt: Color { isDark ? Color(hex: 0xF0F2F5) : Color(hex: 0x3A3A4A) }

    /// Secondary text (labels, subtitles) — mid-tone
    var textSecondary: Color { isDark ? Color(hex: 0xA0A7B5) : Color(hex: 0x888888) }

    /// Tertiary text (hints, faint labels) — recedes into bg
    var textTertiary: Color { isDark ? Color(hex: 0x5A6270) : Color(hex: 0xAAAAAA) }
    var textQuaternary: Color { isDark ? Color(hex: 0x3E4550) : Color(hex: 0xCCCCCC) }

    /// Muted body text
    var textMuted: Color { isDark ? Color(hex: 0x7A8290) : Color(hex: 0x999999) }

    /// Stat values
    var statValue: Color { isDark ? Color(hex: 0xD8DCE4) : Color(hex: 0x4A4A5A) }

    /// Score large number — full white for maximum pop
    var scoreLarge: Color { isDark ? Color(hex: 0xFFFFFF) : Color(hex: 0x2A2A3A) }

    // MARK: - Grid / Cells

    /// Empty cell fill — subtle depth, not flat holes
    var emptyCellTop: Color { isDark ? Color(hex: 0x1C1E26) : Color(hex: 0xEAEAEE) }
    var emptyCellBottom: Color { isDark ? Color(hex: 0x161820) : Color(hex: 0xE0E0E5) }
    var emptyCellBorder: Color { isDark ? Color(hex: 0x2A2D38) : Color(hex: 0xD0D0D8) }
    var emptyCellShadowOpacity: Double { isDark ? 0.2 : 0.04 }
    /// Faint inner glow for dark empty cells
    var emptyCellInnerGlow: Color { isDark ? Color(hex: 0xFFFFFF) : .clear }
    var emptyCellInnerGlowOpacity: Double { isDark ? 0.03 : 0.0 }

    /// Colored bloom around filled tiles in dark mode
    var tileGlowRadius: CGFloat { isDark ? 8 : 0 }
    var tileGlowOpacity: Double { isDark ? 0.35 : 0.0 }

    // MARK: - Mixing Lane

    /// Empty glass in mixing lane
    var mixGlassTop: Color { isDark ? Color(hex: 0x1A1C24) : Color(hex: 0xF0F0F4) }
    var mixGlassBottom: Color { isDark ? Color(hex: 0x151720) : Color(hex: 0xE8E8ED) }
    var mixGlassDash: Color { isDark ? Color(hex: 0x333844) : Color(hex: 0xCCCCD4) }

    /// Mixing tile glass background
    var mixTileBgTop: Color { isDark ? Color(hex: 0x1C1E26) : Color(hex: 0xF2F2F6) }
    var mixTileBgBottom: Color { isDark ? Color(hex: 0x161820) : Color(hex: 0xE6E6EB) }

    // MARK: - Dividers / Separators

    var divider: Color { isDark ? Color(hex: 0x262A34) : Color(hex: 0xDDDDDD) }
    var dividerOpacity: Double { isDark ? 0.6 : 0.5 }

    // MARK: - Overlays

    /// Overlay card background
    var overlayCardFill: Color { isDark ? Color(hex: 0x181A22) : .white }
    var overlayCardOpacity: Double { isDark ? 0.95 : 0.9 }
    var overlayBgDim: Double { isDark ? 0.55 : 0.3 }

    // MARK: - Buttons

    /// Primary button (dark pill) — inverted for dark mode
    var primaryButtonBg: Color { isDark ? Color(hex: 0xF0F2F5) : Color(hex: 0x2A2A2A) }
    var primaryButtonText: Color { isDark ? Color(hex: 0x0F1014) : .white }

    /// Secondary button
    var secondaryButtonBg: Color { isDark ? Color(hex: 0x1C1E26) : .white }
    var secondaryButtonBgOpacity: Double { isDark ? 0.9 : 0.8 }
    var secondaryButtonBorder: Color { isDark ? Color(hex: 0x3A3E48) : Color(hex: 0x2A2A2A) }

    /// Icon button color
    var iconDefault: Color { isDark ? Color(hex: 0xB0B6C0) : Color(hex: 0x4A4A4A) }
    var iconMuted: Color { isDark ? Color(hex: 0x6A7080) : Color(hex: 0x555555) }

    // MARK: - Shadows

    var shadowOpacity: Double { isDark ? 0.3 : 0.06 }

    // MARK: - Navigation bar

    var navBarBg: Material { isDark ? .ultraThinMaterial : .ultraThinMaterial }
    var navBarDivider: Color { isDark ? Color(hex: 0x1E2028) : Color(hex: 0xDDDDDD) }
    /// Inactive nav icon — very dim in dark mode so game stays focal
    var navIconInactive: Color { isDark ? Color(hex: 0x4A5060) : Color(hex: 0xAAAAAA) }
    /// Active nav icon — brighter
    var navIconActive: Color { isDark ? Color(hex: 0xD0D4DC) : Color(hex: 0x3A3A4A) }

    // MARK: - Toast

    var toastFill: Color { isDark ? Color(hex: 0x1C1E26) : .white }
    var toastFillOpacity: Double { isDark ? 0.92 : 0.85 }
    var toastText: Color { isDark ? Color(hex: 0xF0F2F5) : Color(hex: 0x3A3A4A) }

    // MARK: - Dot grid

    var dotGridColor: Color { isDark ? .white : .black }
    var dotGridOpacity: Double { isDark ? 0.03 : 0.08 }

    // MARK: - Tunnel background dots

    var tunnelDotBrightness: CGFloat { isDark ? 0.55 : 0.35 }

    // MARK: - Achievement toast bg
    var achievementToastBg: Color { isDark ? Color(hex: 0x181A22) : .white }
    var achievementToastBgOpacity: Double { isDark ? 0.97 : 0.95 }

    // MARK: - Empty states / locked items
    var lockedBgTop: Color { isDark ? Color(hex: 0x1C1E26) : Color(hex: 0xEDEDEF) }
    var lockedBgBottom: Color { isDark ? Color(hex: 0x161820) : Color(hex: 0xE0E0E2) }

    // MARK: - Specular / glass highlights
    var specularOpacity: Double { isDark ? 0.12 : 0.4 }
    var topEdgeCatchOpacity: Double { isDark ? 0.08 : 0.25 }
    var glassBorderStartOpacity: Double { isDark ? 0.12 : 0.5 }
    var glassBorderEndOpacity: Double { isDark ? 0.03 : 0.1 }

    // MARK: - Hint pill
    var hintActiveBg: Color { isDark ? Color(hex: 0x5A9BC7).opacity(0.2) : Color(hex: 0x5A9BC7).opacity(0.1) }
    var hintInactiveBg: Color { isDark ? Color(hex: 0x1C1E26) : Color(hex: 0xEEEEEE) }
}
