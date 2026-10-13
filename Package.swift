// swift-tools-version: 6.2
import PackageDescription

// Tralphium for macOS: a lightweight desktop shell (shelf, launchpad, control
// panel). No third-party dependencies. See PLAN.md.
let package = Package(
    name: "Tralphium",
    // Liquid Glass (glassEffect / NSGlassEffectView) exists from macOS 26.
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "Tralphium", targets: ["Tralphium"]),
    ],
    targets: [
        // UI-free logic, tested. Stays free of AppKit and SwiftUI.
        .target(name: "TralphiumCore"),
        // The app: panels, views, system integration.
        .executableTarget(name: "Tralphium", dependencies: ["TralphiumCore"]),
        .testTarget(name: "TralphiumCoreTests", dependencies: ["TralphiumCore"]),
    ]
)
