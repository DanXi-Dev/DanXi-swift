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
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", from: "0.2.2"),
        .package(url: "https://github.com/stleamist/BetterSafariView.git", .upToNextMajor(from: "2.4.2")),
        .package(name: "DanXiKit", path: "../DanXi Kit"),
        .package(name: "ViewUtils", path: "../View Utils"),
        .package(name: "Utils", path: "../Utils"),
    ],
    targets: [
        .regexTarget(name: "DanXiUI", dependencies: ["SwiftUIX", "BetterSafariView", "DanXiKit", "ViewUtils", "Utils"], path: ".", resources: [.copy("Preview")]),
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

