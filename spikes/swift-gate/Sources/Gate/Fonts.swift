import SwiftUI
import CoreText

/// Registers the bundled Fraunces + Inter variable fonts so they are available
/// to `Font.custom(...)` regardless of what is installed on the Mac.
///
/// v1 uses `Bundle.module`, whose SwiftPM-generated accessor only ever looks at
/// `Bundle.main.bundleURL/<Package>_<Target>.bundle` — i.e. the `.app` root.
/// Putting a bundle there makes `codesign` fail with "unsealed contents present
/// in the bundle root", so this spike resolves the fonts by hand instead and
/// keeps everything sealed under `Contents/`.
enum Fonts {
    private static let registered: Bool = {
        for name in ["Fraunces", "Inter"] {
            guard let url = locate(name) else {
                FileHandle.standardError.write(Data("Gate: missing font \(name).ttf\n".utf8))
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                FileHandle.standardError.write(Data("Gate: font register failed for \(name)\n".utf8))
            }
        }
        return true
    }()

    /// Idempotent — call once at launch.
    static func register() { _ = registered }

    private static func locate(_ name: String) -> URL? {
        // Packaged .app: Contents/Resources/<name>.ttf
        if let url = Bundle.main.url(forResource: name, withExtension: "ttf") { return url }

        // `swift run` / bare binary: the SwiftPM resource bundle sits beside it.
        let neighbours = [
            Bundle.main.bundleURL,
            Bundle.main.executableURL?.deletingLastPathComponent(),
        ].compactMap { $0 }

        for dir in neighbours {
            let candidate = dir
                .appendingPathComponent("SwiftGate_Gate.bundle")
                .appendingPathComponent("Contents/Resources")
                .appendingPathComponent("\(name).ttf")
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }

            let flat = dir
                .appendingPathComponent("SwiftGate_Gate.bundle")
                .appendingPathComponent("\(name).ttf")
            if FileManager.default.fileExists(atPath: flat.path) { return flat }
        }
        return nil
    }
}
