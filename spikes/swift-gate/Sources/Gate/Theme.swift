import SwiftUI

// Dark palette lifted verbatim from force-old/Sources/Force/Theme.swift (.dark).
// Spike is dark-only, so this is a flat enum of colours rather than a theme manager.

extension Color {
    init(rgb: UInt32) {
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

enum Ink {
    static let base             = Color(rgb: 0x141515)
    static let containerLow     = Color(rgb: 0x1B1C1D)
    static let container        = Color(rgb: 0x222324)
    static let containerHigh    = Color(rgb: 0x2A2B2C)
    static let containerHighest = Color(rgb: 0x313334)
    static let bright           = Color(rgb: 0x3A3C3D)
    static let ink              = Color(rgb: 0xF2F2F0)
    static let inkContainer     = Color(rgb: 0xC9C9C6)
    static let ash              = Color(rgb: 0xDADAD7)
    static let mute             = Color(rgb: 0x9A9E9F)
    static let stone            = Color(rgb: 0x60646A)
    static let outline          = Color(rgb: 0x3C3F40)
    static let outlineSoft      = Color(rgb: 0x2A2C2D)
    static let onPrimary        = Color(rgb: 0x141515)
}

enum Face {
    static let display = "Fraunces"
    static let ui      = "Inter"

    static let claim   = Font.custom(display, size: 44).weight(.medium)
    static let closing = Font.custom(display, size: 30).weight(.medium)
    static let meta    = Font.custom(ui, size: 13).weight(.regular)
    static let label   = Font.custom(ui, size: 11).weight(.medium)
    static let button  = Font.custom(ui, size: 13).weight(.semibold)
    static let timer   = Font.custom(ui, size: 12).weight(.medium)
}
