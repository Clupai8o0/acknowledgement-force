import SwiftUI
import AppKit

// MARK: - Color <-> hex

extension Color {
    init(rgb: UInt32) {
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    /// sRGB hex value (0xRRGGBB), used to persist ColorPicker selections.
    var rgbHex: UInt32 {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .black
        let r = UInt32((ns.redComponent * 255).rounded())
        let g = UInt32((ns.greenComponent * 255).rounded())
        let b = UInt32((ns.blueComponent * 255).rounded())
        return (r << 16) | (g << 8) | b
    }
}

// MARK: - Appearance mode

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }
    var label: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "Follow System"
        }
    }
}

// MARK: - Theme palette

// The Digital Curator palette: a strictly monochrome system built on nested
// surface tiers rather than lines. "container*" fields stack like sheets of
// cotton paper; structural boundaries come from tonal shifts, never borders.
struct Theme: Codable, Equatable {
    // Surface tiers — lightest (lowest) pops on top of darker (low/base) washes.
    var base: UInt32              // surface — the page itself
    var containerLow: UInt32      // surface-container-low — section washes
    var container: UInt32         // surface-container
    var containerHigh: UInt32     // surface-container-high — filled inputs
    var containerHighest: UInt32  // surface-container-highest
    var bright: UInt32            // surface-bright — hover lift

    // Ink. `ink` is on-surface (#1a1c1c — never pure black). `inkContainer`
    // is the lighter end of the monochrome "primary" gradient.
    var ink: UInt32
    var inkContainer: UInt32
    var ash: UInt32               // strong secondary text
    var mute: UInt32              // on-surface-variant
    var stone: UInt32             // disabled / faint
    var outline: UInt32           // only ever used at low opacity (ghost border)
    var outlineSoft: UInt32
    var onPrimary: UInt32         // text/icon riding on `ink` fills

    // Compatibility aliases mapped onto the monochrome system.
    var canvas: UInt32 { containerLow }   // legacy "lowest" base
    var surface: UInt32 { containerHigh } // legacy soft surface
    var hairline: UInt32 { outline }
    var hairlineSoft: UInt32 { outlineSoft }
    var charcoal: UInt32 { inkContainer }
    var accent: UInt32 { ink }            // emphasis stays monochrome
    var sale: UInt32 { ink }
    var info: UInt32 { ink }

    static let light = Theme(
        base: 0xF9F9F9,
        containerLow: 0xF3F3F3,
        container: 0xEEEEEE,
        containerHigh: 0xE8E8E8,
        containerHighest: 0xE3E3E3,
        bright: 0xFFFFFF,
        ink: 0x1A1C1C,
        inkContainer: 0x3A3C3D,
        ash: 0x2E3133,
        mute: 0x6B6F72,
        stone: 0xA9ADB0,
        outline: 0xC4C7C9,
        outlineSoft: 0xD8DADC,
        onPrimary: 0xFFFFFF
    )

    static let dark = Theme(
        base: 0x141515,
        containerLow: 0x1B1C1D,
        container: 0x222324,
        containerHigh: 0x2A2B2C,
        containerHighest: 0x313334,
        bright: 0x3A3C3D,
        ink: 0xF2F2F0,
        inkContainer: 0xC9C9C6,
        ash: 0xDADAD7,
        mute: 0x9A9E9F,
        stone: 0x60646A,
        outline: 0x3C3F40,
        outlineSoft: 0x2A2C2D,
        onPrimary: 0x141515
    )
}

// MARK: - Theme manager

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let mode = "af-appearance-mode-v1"
        static let light = "af-theme-light-v1"
        static let dark = "af-theme-dark-v1"
    }

    @Published var mode: AppearanceMode { didSet { persistMode(); apply() } }
    @Published var lightTheme: Theme { didSet { persist(lightTheme, Keys.light); apply() } }
    @Published var darkTheme: Theme { didSet { persist(darkTheme, Keys.dark); apply() } }

    /// Read by the `Ink` namespace from any context — kept in sync by `apply()`.
    nonisolated(unsafe) static var current: Theme = .dark

    private init() {
        let savedMode = defaults.string(forKey: Keys.mode).flatMap(AppearanceMode.init(rawValue:)) ?? .dark
        mode = savedMode
        lightTheme = Self.load(Keys.light) ?? .light
        darkTheme = Self.load(Keys.dark) ?? .dark
        apply()
    }

    private var systemIsDark: Bool {
        NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    /// The palette in effect right now, accounting for system appearance.
    var effective: Theme {
        switch mode {
        case .light: return lightTheme
        case .dark: return darkTheme
        case .system: return systemIsDark ? darkTheme : lightTheme
        }
    }

    /// Whichever stored theme the user's edits should land on.
    var editingIsDark: Bool {
        switch mode {
        case .light: return false
        case .dark: return true
        case .system: return systemIsDark
        }
    }

    func updateActive(_ transform: (inout Theme) -> Void) {
        if editingIsDark { transform(&darkTheme) } else { transform(&lightTheme) }
    }

    func resetActive() {
        if editingIsDark { darkTheme = .dark } else { lightTheme = .light }
    }

    /// Re-resolve when the OS appearance changes under `.system` mode.
    func refreshSystem() {
        if mode == .system { apply() }
    }

    private func apply() {
        Self.current = effective
        objectWillChange.send()
    }

    private func persistMode() { defaults.set(mode.rawValue, forKey: Keys.mode) }

    private func persist(_ theme: Theme, _ key: String) {
        if let data = try? JSONEncoder().encode(theme) { defaults.set(data, forKey: key) }
    }

    private static func load(_ key: String) -> Theme? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Theme.self, from: data)
    }
}
