//
//  PrismColor.swift
//  aberration
//
//  24-color RYB wheel with midpoint mixing
//

import SwiftUI

struct PrismColor: Hashable, Equatable, Sendable, Identifiable {
    let wheelIndex: Int
    var id: Int { wheelIndex }

    // MARK: - Color Data (24 positions on RYB wheel, 15° apart)

    static let names: [String] = [
        "Red", "Scarlet", "Vermillion", "Tangerine",
        "Orange", "Amber", "Gold", "Lemon",
        "Yellow", "Lime", "Chartreuse", "Mint",
        "Green", "Jade", "Teal", "Cerulean",
        "Blue", "Azure", "Indigo", "Violet",
        "Purple", "Plum", "Magenta", "Crimson"
    ]

    static let hexValues: [UInt] = [
        0xDF1F1F, 0xDF371F, 0xDF4F1F, 0xDF671F,  // Red..Tangerine
        0xDF7F1F, 0xDF971F, 0xDFAF1F, 0xDFC71F,  // Orange..Lemon
        0xDFDF1F, 0xA3DF1F, 0x67DF1F, 0x2BDF1F,  // Yellow..Mint
        0x1FDF4F, 0x1FDF97, 0x1FDFDF, 0x1F97DF,  // Green..Cerulean
        0x1F4FDF, 0x1F1FDF, 0x4F1FDF, 0x7F1FDF,  // Blue..Violet
        0xAF1FDF, 0xDF1FD3, 0xDF1F97, 0xDF1F5B   // Purple..Crimson
    ]

    /// Depth = minimum mixing steps from primaries
    static let depths: [Int] = [
        0, 3, 2, 3, 1, 3, 2, 3,  // Red..Lemon
        0, 3, 2, 3, 1, 3, 2, 3,  // Yellow..Cerulean
        0, 3, 2, 3, 1, 3, 2, 3   // Blue..Crimson
    ]

    /// Recipe: which two color indices mix to create this color (BFS-optimal by depth)
    static let recipes: [Int: (Int, Int)] = [
        4: (0, 8),   12: (8, 16),  20: (0, 16),     // depth 1: secondaries
        2: (0, 4),   6: (0, 12),   10: (4, 16),      // depth 2
        14: (8, 20),  18: (16, 20), 22: (0, 20),     // depth 2
        1: (0, 2),   3: (0, 6),    5: (0, 10),       // depth 3
        7: (2, 12),  9: (4, 14),   11: (6, 16),      // depth 3
        13: (8, 18),  15: (10, 20), 17: (12, 22),    // depth 3
        19: (0, 14),  21: (0, 18),  23: (0, 22)      // depth 3
    ]

    // MARK: - Computed Properties

    var name: String { Self.names[wheelIndex] }
    var hexValue: UInt { Self.hexValues[wheelIndex] }
    var color: Color { Color(hex: hexValue) }
    var depth: Int { Self.depths[wheelIndex] }
    var isPrimary: Bool { wheelIndex == 0 || wheelIndex == 8 || wheelIndex == 16 }

    /// Short 2-3 letter abbreviation for tile labels
    static let shortNames: [String] = [
        "RED", "SCR", "VRM", "TNG",
        "ORG", "AMB", "GLD", "LMN",
        "YLW", "LIM", "CHR", "MNT",
        "GRN", "JAD", "TEL", "CER",
        "BLU", "AZR", "IND", "VIO",
        "PUR", "PLM", "MAG", "CRM"
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
    static let yellow = PrismColor(wheelIndex: 8)
    static let blue = PrismColor(wheelIndex: 16)
    static let primaries: [PrismColor] = [.red, .yellow, .blue]
    static let allColors: [PrismColor] = (0..<24).map { PrismColor(wheelIndex: $0) }

    static func byIndex(_ i: Int) -> PrismColor {
        PrismColor(wheelIndex: ((i % 24) + 24) % 24)
    }

    // MARK: - Mixing (midpoint on shorter arc of 24-position wheel)

    static func mix(_ a: PrismColor, _ b: PrismColor) -> PrismColor {
        let ai = a.wheelIndex
        let bi = b.wheelIndex
        if ai == bi { return a }

        // Normalize so lo < hi — guarantees commutativity
        let lo = min(ai, bi)
        let hi = max(ai, bi)
        let clockwise = hi - lo        // 1..23
        let counter = 24 - clockwise   // 1..23

        let result: Int
        if clockwise < counter {
            // Shorter arc goes lo → hi (clockwise)
            let mid = Double(lo) + Double(clockwise) / 2.0
            result = Int(mid.rounded()) % 24
        } else if counter < clockwise {
            // Shorter arc goes hi → lo (wrapping past 0)
            let mid = Double(hi) + Double(counter) / 2.0
            result = Int(mid.rounded()) % 24
        } else {
            // Exactly opposite — deterministic midpoint
            result = (lo + 6) % 24
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
        1:  (byIndex(0),  byIndex(2)),   // Red + Vermillion → Scarlet
        2:  (byIndex(0),  byIndex(4)),   // Red + Orange → Vermillion
        3:  (byIndex(2),  byIndex(4)),   // Vermillion + Orange → Tangerine
        4:  (byIndex(0),  byIndex(8)),   // Red + Yellow → Orange
        5:  (byIndex(2),  byIndex(8)),   // Vermillion + Yellow → Amber
        6:  (byIndex(4),  byIndex(8)),   // Orange + Yellow → Gold
        7:  (byIndex(6),  byIndex(8)),   // Gold + Yellow → Lemon
        9:  (byIndex(8),  byIndex(10)),  // Yellow + Chartreuse → Lime
        10: (byIndex(8),  byIndex(12)),  // Yellow + Green → Chartreuse
        11: (byIndex(10), byIndex(12)),  // Chartreuse + Green → Mint
        12: (byIndex(8),  byIndex(16)),  // Yellow + Blue → Green
        13: (byIndex(12), byIndex(14)),  // Green + Teal → Jade
        14: (byIndex(12), byIndex(16)),  // Green + Blue → Teal
        15: (byIndex(14), byIndex(16)),  // Teal + Blue → Cerulean
        17: (byIndex(16), byIndex(18)),  // Blue + Indigo → Azure
        18: (byIndex(16), byIndex(20)),  // Blue + Purple → Indigo
        19: (byIndex(16), byIndex(22)),  // Blue + Magenta → Violet
        20: (byIndex(0),  byIndex(16)),  // Red + Blue → Purple
        21: (byIndex(20), byIndex(22)),  // Purple + Magenta → Plum
        22: (byIndex(0),  byIndex(20)),  // Red + Purple → Magenta
        23: (byIndex(0),  byIndex(22)),  // Red + Magenta → Crimson
    ]

    /// Legacy: kept for compatibility. Returns the direct pair as an array.
    static let optimalIngredients: [Int: [PrismColor]] = {
        var result: [Int: [PrismColor]] = [
            0: [PrismColor(wheelIndex: 0)],
            8: [PrismColor(wheelIndex: 8)],
            16: [PrismColor(wheelIndex: 16)]
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
