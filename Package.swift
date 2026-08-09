// swift-tools-version: 6.0
import PackageDescription
import Foundation

// Force is split into four targets:
//
//   ForceKit      — platform-agnostic core: models, contract parser, gate
//                   logic, persistence abstractions, and the Supabase sync
//                   engine. Builds on macOS, Linux, and Windows.
//   ForceCLI      — `force-cli`, a terminal front end over ForceKit.
//   ForceDesktop  — `force-desktop`, the native GUI for Linux and Windows
//                   (GTK4 / WinUI via SwiftCrossUI), built on ForceKit. Also
//                   builds on macOS (AppKit backend) for local verification —
//                   the shipping Mac client stays the `Force` SwiftUI target.
//   Force         — the macOS SwiftUI app. Declared only when the manifest is
//                   evaluated on macOS, so `swift build` on Linux/Windows
//                   builds just the portable targets.

// The desktop GUI pulls in SwiftCrossUI and, transitively, its GTK (Linux) and
// WinUI (Windows) C backends — which only compile with their platform's dev
// headers present. To keep a bare `swift build` building just the portable
// targets (ForceKit + force-cli) the way it always has, the GUI is opt-in:
// set FORCE_DESKTOP=1 to add the dependency and the force-desktop product.
//
//   Build the GUI:  FORCE_DESKTOP=1 swift build --product force-desktop
//
let buildDesktop = ProcessInfo.processInfo.environment["FORCE_DESKTOP"] != nil

var products: [Product] = [
    .library(name: "ForceKit", targets: ["ForceKit"]),
    .executable(name: "force-cli", targets: ["ForceCLI"]),
]

var targets: [Target] = [
    .target(
        name: "ForceKit",
        path: "Sources/ForceKit"
    ),
    .executableTarget(
        name: "ForceCLI",
        dependencies: ["ForceKit"],
        path: "Sources/ForceCLI"
    ),
]

var dependencies: [Package.Dependency] = []

if buildDesktop {
    products.append(.executable(name: "force-desktop", targets: ["ForceDesktop"]))
    dependencies.append(
        // The Windows/Linux GUI toolkit. SwiftCrossUI renders SwiftUI-style
        // declarative views natively via GTK4 (Linux) and WinUI (Windows);
        // on macOS it falls back to AppKit, used here only to compile-check the
        // ForceDesktop target — the shipping Mac client is the `Force` SwiftUI
        // target.
        .package(url: "https://github.com/stackotter/swift-cross-ui", from: "0.7.0")
    )
    targets.append(
        .executableTarget(
            name: "ForceDesktop",
            dependencies: [
                "ForceKit",
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui"),
            ],
            path: "Sources/ForceDesktop"
        )
    )
}

#if os(macOS)
products.append(.executable(name: "Force", targets: ["Force"]))
targets.append(
    .executableTarget(
        name: "Force",
        dependencies: ["ForceKit"],
        path: "Sources/Force",
        resources: [
            .process("Resources/Fonts")
        ]
    )
)
#endif

let package = Package(
    name: "Force",
    platforms: [
        .macOS(.v14)
    ],
    products: products,
    dependencies: dependencies,
    targets: targets
)
