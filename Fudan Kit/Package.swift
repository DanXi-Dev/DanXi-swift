// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FudanKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16), .watchOS(.v9)
    ],
    products: [
        .library(name: "FudanKit", targets: ["FudanKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/mattmassicotte/Queue", from: "0.1.4"),
        .package(path: "../Utils"),
    ],
    targets: [
        .target(name: "FudanKit", dependencies: ["SwiftSoup", "Utils", "KeychainAccess", "SwiftyJSON", "Queue"], path: "."),
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
