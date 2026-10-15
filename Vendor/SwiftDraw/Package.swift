// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SwiftDraw",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
    products: [.library(name: "SwiftDraw", targets: ["SwiftDraw"])],
    targets: [.target(name: "SwiftDraw", path: "SwiftDraw", swiftSettings: [
        .enableUpcomingFeature("ExistentialAny"), .swiftLanguageMode(.v6)
    ])]
)
