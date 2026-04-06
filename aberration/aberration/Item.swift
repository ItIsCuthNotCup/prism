//
//  PrismColor.swift
//  aberration
//
//  48-color RYB wheel with midpoint mixing
//

import SwiftUI

struct PrismColor: Hashable, Equatable, Sendable, Identifiable {
    let wheelIndex: Int
    var id: Int { wheelIndex }

    /// Number of positions on the RYB color wheel
    static let wheelSize = 48

    // MARK: - Color Data (48 positions on RYB wheel, 7.5° apart)

    static let names: [String] = [
        // Red segment (0-15)
        "Red", "Flame", "Scarlet", "Cinnabar",
        "Vermillion", "Rust", "Tangerine", "Persimmon",
        "Orange", "Marigold", "Amber", "Honey",
        "Gold", "Flax", "Lemon", "Canary",
        // Yellow segment (16-31)
        "Yellow", "Pear", "Lime", "Fern",
        "Chartreuse", "Spring", "Mint", "Emerald",
        "Green", "Seafoam", "Jade", "Lagoon",
        "Teal", "Cyan", "Cerulean", "Cobalt",
        // Blue segment (32-47)
        "Blue", "Sapphire", "Azure", "Twilight",
        "Indigo", "Amethyst", "Violet", "Grape",
        "Purple", "Orchid", "Plum", "Fuchsia",
        "Magenta", "Ruby", "Crimson", "Cherry"
    ]

    static let hexValues: [UInt] = [
        // Red → Orange (0-8)
        0xDF1F1F, 0xDF2B1F, 0xDF371F, 0xDF431F,
        0xDF4F1F, 0xDF5B1F, 0xDF671F, 0xDF731F,
        // Orange → Yellow (8-16)
        0xDF7F1F, 0xDF8B1F, 0xDF971F, 0xDFA31F,
        0xDFAF1F, 0xDFBB1F, 0xDFC71F, 0xDFD31F,
        // Yellow → Green (16-24)
        0xDFDF1F, 0xC1DF1F, 0xA3DF1F, 0x85DF1F,
        0x67DF1F, 0x49DF1F, 0x2BDF1F, 0x25DF37,
        // Green → Teal (24-28)
        0x1FDF4F, 0x1FDF73, 0x1FDF97, 0x1FDFBB,
        0x1FDFDF, 0x1FBBDF, 0x1F97DF, 0x1F73DF,
        // Blue → Purple (32-40)
        0x1F4FDF, 0x1F37DF, 0x1F1FDF, 0x371FDF,
        0x4F1FDF, 0x671FDF, 0x7F1FDF, 0x971FDF,
        // Purple → Red (40-47)
        0xAF1FDF, 0xC71FD9, 0xDF1FD3, 0xDF1FB5,
        0xDF1F97, 0xDF1F79, 0xDF1F5B, 0xDF1F3D
    ]

    /// Depth = minimum mixing steps from primaries
    /// Pattern repeats 3× (one per primary segment of 16):
    /// [0, 4, 3, 4, 2, 4, 3, 4, 1, 4, 3, 4, 2, 4, 3, 4]
    static let depths: [Int] = [
        0, 4, 3, 4, 2, 4, 3, 4, 1, 4, 3, 4, 2, 4, 3, 4,  // Red..Canary
        0, 4, 3, 4, 2, 4, 3, 4, 1, 4, 3, 4, 2, 4, 3, 4,  // Yellow..Cobalt
        0, 4, 3, 4, 2, 4, 3, 4, 1, 4, 3, 4, 2, 4, 3, 4   // Blue..Cherry
    ]

    /// Recipe: which two color indices mix to create this color (BFS-optimal by depth).
    /// Even indices are converted from old 24-wheel (×2). Odd indices use adjacent neighbors.
    static let recipes: [Int: (Int, Int)] = [
        // Depth 1: secondaries (primary + primary)
        8:  (0, 16),     // Red + Yellow → Orange
        24: (16, 32),    // Yellow + Blue → Green
        40: (0, 32),     // Red + Blue → Purple

        // Depth 2: tertiary (primary + secondary)
        4:  (0, 8),      // Red + Orange → Vermillion
        12: (0, 24),     // Red + Green → Gold
        20: (8, 32),     // Orange + Blue → Chartreuse
        28: (16, 40),    // Yellow + Purple → Teal
        36: (32, 40),    // Blue + Purple → Indigo
        44: (0, 40),     // Red + Purple → Magenta

        // Depth 3: quaternary
        2:  (0, 4),      // Red + Vermillion → Scarlet
        6:  (0, 12),     // Red + Gold → Tangerine
        10: (0, 20),     // Red + Chartreuse → Amber
        14: (4, 24),     // Vermillion + Green → Lemon
        18: (8, 28),     // Orange + Teal → Lime
        22: (12, 32),    // Gold + Blue → Mint
        26: (16, 36),    // Yellow + Indigo → Jade
        30: (20, 40),    // Chartreuse + Purple → Cerulean
        34: (24, 44),    // Green + Magenta → Azure
        38: (0, 28),     // Red + Teal → Violet
        42: (0, 36),     // Red + Indigo → Plum
        46: (0, 44),     // Red + Magenta → Crimson

        // Depth 4: quinary (adjacent neighbor pairs)
        1:  (0, 2),      3:  (2, 4),      5:  (4, 6),      7:  (6, 8),
        9:  (8, 10),     11: (10, 12),    13: (12, 14),    15: (14, 16),
        17: (16, 18),    19: (18, 20),    21: (20, 22),    23: (22, 24),
        25: (24, 26),    27: (26, 28),    29: (28, 30),    31: (30, 32),
        33: (32, 34),    35: (34, 36),    37: (36, 38),    39: (38, 40),
        41: (40, 42),    43: (42, 44),    45: (44, 46),    47: (46, 0)
    ]

    // MARK: - Computed Properties

    var name: String { Self.names[wheelIndex] }
    var hexValue: UInt { Self.hexValues[wheelIndex] }
    var color: Color { Color(hex: hexValue) }
    var depth: Int { Self.depths[wheelIndex] }
    var isPrimary: Bool { wheelIndex == 0 || wheelIndex == 16 || wheelIndex == 32 }

    /// Short 2-3 letter abbreviation for tile labels
    static let shortNames: [String] = [
        // Red segment
        "RED", "FLM", "SCR", "CNB",
        "VRM", "RST", "TNG", "PRS",
        "ORG", "MRG", "AMB", "HNY",
        "GLD", "FLX", "LMN", "CNR",
        // Yellow segment
        "YLW", "PER", "LIM", "FRN",
        "CHR", "SPR", "MNT", "EMR",
        "GRN", "SFM", "JAD", "LGN",
        "TEL", "CYN", "CER", "CBL",
        // Blue segment
        "BLU", "SPH", "AZR", "TWL",
        "IND", "AMT", "VIO", "GRP",
        "PUR", "ORC", "PLM", "FCS",
        "MAG", "RBY", "CRM", "CHR"
    ]
    var shortName: String { Self.shortNames[wheelIndex] }

    var highlightColor: Color {
        let hex = Self.hexValues[wheelIndex]
        let r = (hex >> 16) & 0xFF
        let g = (hex >> 8) & 0xFF
        let b = hex & 0xFF
        let lr = r + (255 - r) * 4 / 10
        let lg = g + (255 - g) * 4 / 10
        let lb = b + (255 - b) * 4 / 10
        return Color(hex: (lr << 16) | (lg << 8) | lb)
    }

    // MARK: - Standard Colors

    static let red = PrismColor(wheelIndex: 0)
    static let yellow = PrismColor(wheelIndex: 16)
    static let blue = PrismColor(wheelIndex: 32)
    static let primaries: [PrismColor] = [.red, .yellow, .blue]
    static let allColors: [PrismColor] = (0..<48).map { PrismColor(wheelIndex: $0) }

    static func byIndex(_ i: Int) -> PrismColor {
        PrismColor(wheelIndex: ((i % 48) + 48) % 48)
    }

    // MARK: - Mixing (midpoint on shorter arc of 48-position wheel)

    static func mix(_ a: PrismColor, _ b: PrismColor) -> PrismColor {
        let ai = a.wheelIndex
        let bi = b.wheelIndex
        if ai == bi { return a }

        // Normalize so lo < hi — guarantees commutativity
        let lo = min(ai, bi)
        let hi = max(ai, bi)
        let clockwise = hi - lo        // 1..47
        let counter = 48 - clockwise   // 1..47

        let result: Int
        if clockwise < counter {
            // Shorter arc goes lo → hi (clockwise)
            let mid = Double(lo) + Double(clockwise) / 2.0
            result = Int(mid.rounded()) % 48
        } else if counter < clockwise {
            // Shorter arc goes hi → lo (wrapping past 0)
            let mid = Double(hi) + Double(counter) / 2.0
            result = Int(mid.rounded()) % 48
        } else {
            // Exactly opposite — deterministic midpoint
            result = (lo + 12) % 48
        }
        return byIndex(result)
    }

    // MARK: - Decomposition to Primary Ingredients

    /// Recursively decompose a color into the primary tiles needed to create it.
    static func primaryIngredients(for color: PrismColor) -> [PrismColor] {
        if color.isPrimary { return [color] }
        guard let (a, b) = recipes[color.wheelIndex] else { return [color] }
        return primaryIngredients(for: byIndex(a)) + primaryIngredients(for: byIndex(b))
    }

    /// Direct pair for every target: exactly 2 colors that mix to produce it.
    /// Hand-curated so every combination is intuitive (adjacent on the wheel).
    static let directPair: [Int: (PrismColor, PrismColor)] = [
        // Even indices (from old 24-wheel, remapped ×2)
        2:  (byIndex(0),  byIndex(4)),   // Red + Vermillion → Scarlet
        4:  (byIndex(0),  byIndex(8)),   // Red + Orange → Vermillion
        6:  (byIndex(4),  byIndex(8)),   // Vermillion + Orange → Tangerine
        8:  (byIndex(0),  byIndex(16)),  // Red + Yellow → Orange
        10: (byIndex(4),  byIndex(16)),  // Vermillion + Yellow → Amber
        12: (byIndex(8),  byIndex(16)),  // Orange + Yellow → Gold
        14: (byIndex(12), byIndex(16)),  // Gold + Yellow → Lemon
        18: (byIndex(16), byIndex(20)),  // Yellow + Chartreuse → Lime
        20: (byIndex(16), byIndex(24)),  // Yellow + Green → Chartreuse
        22: (byIndex(20), byIndex(24)),  // Chartreuse + Green → Mint
        24: (byIndex(16), byIndex(32)),  // Yellow + Blue → Green
        26: (byIndex(24), byIndex(28)),  // Green + Teal → Jade
        28: (byIndex(24), byIndex(32)),  // Green + Blue → Teal
        30: (byIndex(28), byIndex(32)),  // Teal + Blue → Cerulean
        34: (byIndex(32), byIndex(36)),  // Blue + Indigo → Azure
        36: (byIndex(32), byIndex(40)),  // Blue + Purple → Indigo
        38: (byIndex(32), byIndex(44)),  // Blue + Magenta → Violet
        40: (byIndex(0),  byIndex(32)),  // Red + Blue → Purple
        42: (byIndex(40), byIndex(44)),  // Purple + Magenta → Plum
        44: (byIndex(0),  byIndex(40)),  // Red + Purple → Magenta
        46: (byIndex(0),  byIndex(44)),  // Red + Magenta → Crimson

        // Odd indices (adjacent neighbors)
        1:  (byIndex(0),  byIndex(2)),   // Red + Scarlet → Flame
        3:  (byIndex(2),  byIndex(4)),   // Scarlet + Vermillion → Cinnabar
        5:  (byIndex(4),  byIndex(6)),   // Vermillion + Tangerine → Rust
        7:  (byIndex(6),  byIndex(8)),   // Tangerine + Orange → Persimmon
        9:  (byIndex(8),  byIndex(10)),  // Orange + Amber → Marigold
        11: (byIndex(10), byIndex(12)),  // Amber + Gold → Honey
        13: (byIndex(12), byIndex(14)),  // Gold + Lemon → Flax
        15: (byIndex(14), byIndex(16)),  // Lemon + Yellow → Canary
        17: (byIndex(16), byIndex(18)),  // Yellow + Lime → Pear
        19: (byIndex(18), byIndex(20)),  // Lime + Chartreuse → Fern
        21: (byIndex(20), byIndex(22)),  // Chartreuse + Mint → Spring
        23: (byIndex(22), byIndex(24)),  // Mint + Green → Emerald
        25: (byIndex(24), byIndex(26)),  // Green + Jade → Seafoam
        27: (byIndex(26), byIndex(28)),  // Jade + Teal → Lagoon
        29: (byIndex(28), byIndex(30)),  // Teal + Cerulean → Cyan
        31: (byIndex(30), byIndex(32)),  // Cerulean + Blue → Cobalt
        33: (byIndex(32), byIndex(34)),  // Blue + Azure → Sapphire
        35: (byIndex(34), byIndex(36)),  // Azure + Indigo → Twilight
        37: (byIndex(36), byIndex(38)),  // Indigo + Violet → Amethyst
        39: (byIndex(38), byIndex(40)),  // Violet + Purple → Grape
        41: (byIndex(40), byIndex(42)),  // Purple + Plum → Orchid
        43: (byIndex(42), byIndex(44)),  // Plum + Magenta → Fuchsia
        45: (byIndex(44), byIndex(46)),  // Magenta + Crimson → Ruby
        47: (byIndex(46), byIndex(0)),   // Crimson + Red → Cherry
    ]

    /// Legacy: kept for compatibility. Returns the direct pair as an array.
    static let optimalIngredients: [Int: [PrismColor]] = {
        var result: [Int: [PrismColor]] = [
            0:  [PrismColor(wheelIndex: 0)],
            16: [PrismColor(wheelIndex: 16)],
            32: [PrismColor(wheelIndex: 32)]
        ]
        for (target, (a, b)) in directPair {
            result[target] = [a, b]
        }
        return result
    }()

    /// Non-primary colors available up to a given depth.
    static func targets(maxDepth: Int) -> [PrismColor] {
        allColors.filter { $0.depth > 0 && $0.depth <= maxDepth }
    }

    // MARK: - Recipe Steps (for UI hints)

    /// One step in a recipe chain: inputA + inputB → result
    struct RecipeStep {
        let inputA: PrismColor
        let inputB: PrismColor
        let result: PrismColor
    }

    /// Ordered steps to create this color from primaries.
    /// e.g. Magenta → [(Red, Blue, Purple), (Red, Purple, Magenta)]
    static func recipeSteps(for color: PrismColor) -> [RecipeStep] {
        if color.isPrimary { return [] }
        guard let (a, b) = recipes[color.wheelIndex] else { return [] }
        let colorA = byIndex(a)
        let colorB = byIndex(b)
        return recipeSteps(for: colorA)
             + recipeSteps(for: colorB)
             + [RecipeStep(inputA: colorA, inputB: colorB, result: color)]
    }

    /// All intermediate + target colors needed in the recipe chain.
    static func recipeColors(for color: PrismColor) -> Set<PrismColor> {
        var colors = Set<PrismColor>()
        for step in recipeSteps(for: color) {
            colors.insert(step.result)
            colors.insert(step.inputA)
            colors.insert(step.inputB)
        }
        return colors
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
