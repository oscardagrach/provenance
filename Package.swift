// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Provenance",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ProvenanceCore", targets: ["ProvenanceCore"]),
        .executable(name: "provenance", targets: ["provenance"]),
        .executable(name: "ProvenanceApp", targets: ["ProvenanceApp"]),
    ],
    targets: [
        // All logic lives here. No SwiftUI/AppKit imports allowed.
        .target(name: "ProvenanceCore"),

        // Thin CLI over ProvenanceCore — used for fast manual verification.
        .executableTarget(name: "provenance", dependencies: ["ProvenanceCore"]),

        // Thin SwiftUI menu bar app over ProvenanceCore. Bundled by scripts/build-app.sh.
        .executableTarget(name: "ProvenanceApp", dependencies: ["ProvenanceCore"]),

        .testTarget(name: "ProvenanceCoreTests", dependencies: ["ProvenanceCore"]),
    ],
    swiftLanguageModes: [.v6]
)
