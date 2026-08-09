import SwiftUI
import CoreText

/// Registers the bundled Fraunces + Inter variable fonts so they are
/// available to `Font.custom(...)` regardless of what's installed on the Mac.
enum Fonts {
    private static let registered: Bool = {
        let names = ["Fraunces", "Inter"]
        for name in names {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        return true
    }()

    /// Idempotent — call once at launch.
    static func register() { _ = registered }
}
