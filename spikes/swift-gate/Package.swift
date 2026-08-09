// swift-tools-version: 6.0
import PackageDescription

// Spike: "The Evening Gate" — SwiftUI benchmark build.
// Single executable target, no dependencies. Build with `swift build -c release`
// and package with ./package.sh (no Xcode required).

let package = Package(
    name: "SwiftGate",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Gate", targets: ["Gate"])
    ],
    targets: [
        .executableTarget(
            name: "Gate",
            path: "Sources/Gate",
            resources: [
                .process("Resources/Fonts")
            ]
        )
    ]
)
