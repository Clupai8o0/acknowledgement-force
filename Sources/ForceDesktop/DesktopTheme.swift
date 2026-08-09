import SwiftCrossUI

// The Windows/Linux port of "The Digital Curator" design language. The macOS
// app's tokens (DesignSystem.swift / Theme.swift) are reproduced here against
// SwiftCrossUI's primitives so the GUI matches the Mac client.
//
// Two practical differences from the SwiftUI tokens, both SwiftCrossUI
// constraints rather than design choices:
//   • Spacing/radius are `Int` (SwiftCrossUI's padding/spacing/cornerRadius
//     take integer points), not `CGFloat`.
//   • Fonts are the system family with weight steps — SwiftCrossUI 0.7 has no
//     custom-font API, so Fraunces/Inter are approximated by weight. The
//     hierarchy (sizes, weights) is preserved.

extension Color {
    /// Builds a color from a packed 0xRRGGBB value — matches the Mac
    /// `Color(rgb:)` initializer so the palettes stay byte-identical.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Color tokens — adaptive light/dark pairs lifted verbatim from `Theme.light`
/// and `Theme.dark`. They resolve against the platform color scheme.
enum Ink {
    private static func tone(_ light: UInt32, _ dark: UInt32) -> Color {
        .adaptive(light: Color(hex: light), dark: Color(hex: dark))
    }

    // Surface tiers.
    static let base             = tone(0xF9F9F9, 0x141515)
    static let containerLow     = tone(0xF3F3F3, 0x1B1C1D)
    static let container        = tone(0xEEEEEE, 0x222324)
    static let containerHigh    = tone(0xE8E8E8, 0x2A2B2C)
    static let containerHighest = tone(0xE3E3E3, 0x313334)
    static let bright           = tone(0xFFFFFF, 0x3A3C3D)

    // Ink.
    static let ink          = tone(0x1A1C1C, 0xF2F2F0)
    static let inkContainer = tone(0x3A3C3D, 0xC9C9C6)
    static let ash          = tone(0x2E3133, 0xDADAD7)
    static let mute         = tone(0x6B6F72, 0x9A9E9F)
    static let stone        = tone(0xA9ADB0, 0x60646A)
    static let outline      = tone(0xC4C7C9, 0x3C3F40)
    static let outlineSoft  = tone(0xD8DADC, 0x2A2C2D)
    static let onPrimary    = tone(0xFFFFFF, 0x141515)
}

/// Spacing scale (points). Integer to match SwiftCrossUI's layout API.
enum Space {
    static let xxs = 2
    static let xs = 4
    static let sm = 8
    static let md = 12
    static let lg = 20
    static let xl = 28
    static let xxl = 40
    static let section = 56
}

/// Corner radius scale (points).
enum Radius {
    static let xs = 4
    static let sm = 6
    static let md = 8
    static let lg = 14
    static let xl = 20
}

/// Typography — system family, weight-stepped to mirror the Mac hierarchy.
enum Type {
    /// Editorial display (Fraunces on Mac → weighted system here).
    static func display(_ size: Double) -> Font { .system(size: size, weight: .regular) }

    static let headingXL  = Font.system(size: 28, weight: .semibold)
    static let headingLG  = Font.system(size: 22, weight: .semibold)
    static let headingMD  = Font.system(size: 17, weight: .semibold)

    static let bodyMD     = Font.system(size: 16)
    static let bodyStrong = Font.system(size: 16, weight: .medium)

    static let buttonMD   = Font.system(size: 15, weight: .semibold)

    static let captionMD  = Font.system(size: 13)
    static let captionSM  = Font.system(size: 11, weight: .medium)
}
