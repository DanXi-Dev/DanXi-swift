// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FudanKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FudanKit",
            targets: ["FudanKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(path: "../Utils"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FudanKit", dependencies: ["SwiftSoup", "Utils"]),
    ]
)

let swiftSettings: [SwiftSetting] = [
    // -enable-bare-slash-regex becomes
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    // -warn-concurrency becomes
    .enableUpcomingFeature("StrictConcurrency"),
    .unsafeFlags(["-enable-actor-data-race-checks"],
        .when(configuration: .debug)),
]

for target in package.targets {
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings?.append(contentsOf: swiftSettings)
}
