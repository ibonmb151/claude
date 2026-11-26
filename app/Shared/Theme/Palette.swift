import SwiftUI

extension Color {
    /// Crea un color a partir de un número hexadecimal, por ejemplo 0x4A4E55.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Paleta Grafito. Sin negro puro y sin verde lima.
/// El verde y el rojo solo hablan de ganar o perder.
enum Palette {
    // Base
    static let bg = Color(hex: 0xF2F2EE)
    static let card = Color.white
    static let line = Color(hex: 0xEFEFEA)
    static let track = Color(hex: 0xEBEBE6)

    // Grafito
    static let ink = Color(hex: 0x2B2E33)
    static let ink2 = Color(hex: 0x6B7078)
    static let graphite = Color(hex: 0x4A4E55)
    static let graphiteDark = Color(hex: 0x3A3D42)
    static let graphiteSoft = Color(hex: 0xC9CDD2)
    static let selection = Color(hex: 0xE3E5E8)

    // Estados
    static let pos = Color(hex: 0x5FA800)
    static let posText = Color(hex: 0x3F7300)
    static let posBg = Color(hex: 0xEEF8DC)

    static let neg = Color(hex: 0xF2465E)
    static let negText = Color(hex: 0xC21A36)
    static let negBg = Color(hex: 0xFDE4E8)

    static let warn = Color(hex: 0xE89B00)
    static let warnText = Color(hex: 0x8F5D00)
    static let warnBg = Color(hex: 0xFDF1D6)

    static let info = Color(hex: 0x2E90FA)
    static let infoText = Color(hex: 0x1567C9)
    static let infoBg = Color(hex: 0xE3F0FE)

    static let neutralBg = Color(hex: 0xEBEBE6)
    static let stop = Color(hex: 0xC21A36)
    static let paused = Color(hex: 0xB5B5AE)

    // Un color por cosa
    static let teal = Color(hex: 0x00A3A3)
    static let gold = Color(hex: 0xC08A00)
    static let violet = Color(hex: 0x7A5AF8)
    static let magenta = Color(hex: 0xD444F1)
    static let gray = Color(hex: 0x8A8A84)
}

/// Tono de una etiqueta (píldora).
enum Tone {
    case good, warn, bad, info, neutral

    var fg: Color {
        switch self {
        case .good: return Palette.posText
        case .warn: return Palette.warnText
        case .bad: return Palette.negText
        case .info: return Palette.infoText
        case .neutral: return Palette.ink2
        }
    }

    var bg: Color {
        switch self {
        case .good: return Palette.posBg
        case .warn: return Palette.warnBg
        case .bad: return Palette.negBg
        case .info: return Palette.infoBg
        case .neutral: return Palette.neutralBg
        }
    }
}
