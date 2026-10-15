// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DanXiUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "DanXiUI", targets: ["DanXiUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", from: "0.3.2"),
        .package(url: "https://github.com/stleamist/BetterSafariView.git", .upToNextMajor(from: "2.4.2")),
        .package(path: "../Vendor/swift-markdown-ui"),
        .package(path: "../Vendor/SwiftDraw"),
        .package(url: "https://github.com/colinc86/MathJaxSwift", exact: "3.4.0"),
        .package(url: "https://github.com/kean/Pulse.git", from: "5.1.4"),
        .package(name: "DanXiKit", path: "../DanXi Kit"),
        .package(name: "ViewUtils", path: "../View Utils"),
        .package(name: "Utils", path: "../Utils"),
    ],
    targets: [
        .regexTarget(name: "DanXiUI", dependencies: [
            .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            .product(name: "PulseUI", package: "Pulse"),
            "MathJaxSwift", "SwiftDraw", "SwiftUIX", "BetterSafariView", "DanXiKit", "ViewUtils", "Utils"
        ], path: ".", resources: [.copy("Preview")]),
    ]
)

extension Target {
    static func regexTarget(name: String, dependencies: [Target.Dependency], path: String, resources: [Resource]) -> Target {
        let target = target(name: name, dependencies: dependencies, path: path, resources: resources)
        if target.swiftSettings == nil {
            target.swiftSettings = []
        }
        target.swiftSettings?.append(.enableUpcomingFeature("BareSlashRegexLiterals"))
        return target
    }
}
