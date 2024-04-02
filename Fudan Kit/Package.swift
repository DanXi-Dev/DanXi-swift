// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FudanKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "FudanKit", targets: ["FudanKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(path: "../Utils"),
    ],
    targets: [
        .target(name: "FudanKit", dependencies: ["SwiftSoup", "Utils"], path: "."),
    ]
)

// allow usage of regex literal in FudanKit

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
