import SwiftUI

enum TileColor: String, Codable, CaseIterable {
    case red, blue, yellow
    case purple, green, orange

    var isPrimary: Bool {
        switch self {
        case .red, .blue, .yellow: return true
        case .purple, .green, .orange: return false
        }
    }

    var color: Color {
        switch self {
        case .red:    return Color(hex: 0xE63946)
        case .blue:   return Color(hex: 0x457B9D)
        case .yellow: return Color(hex: 0xF4D35E)
        case .purple: return Color(hex: 0x7B2D8B)
        case .green:  return Color(hex: 0x2A9D8F)
        case .orange: return Color(hex: 0xE76F51)
        }
    }

    var highlightColor: Color {
        switch self {
        case .red:    return Color(hex: 0xF07078)
        case .blue:   return Color(hex: 0x6A9BB5)
        case .yellow: return Color(hex: 0xF7E08A)
        case .purple: return Color(hex: 0x9E5AAB)
        case .green:  return Color(hex: 0x55B8AC)
        case .orange: return Color(hex: 0xED9A83)
        }
    }

    static var primaries: [TileColor] { [.red, .blue, .yellow] }

    static func blend(_ a: TileColor, _ b: TileColor) -> TileColor? {
        guard a.isPrimary, b.isPrimary, a != b else { return nil }
        let pair = Set([a, b])
        if pair == Set([.red, .blue])    { return .purple }
        if pair == Set([.blue, .yellow]) { return .green }
        if pair == Set([.red, .yellow])  { return .orange }
        return nil
    }

    static func randomPrimary() -> TileColor {
        primaries.randomElement()!
    }
}

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
