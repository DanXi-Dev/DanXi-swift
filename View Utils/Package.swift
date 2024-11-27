// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ViewUtils",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "ViewUtils", targets: ["ViewUtils"]),
    ],
    dependencies: [
        .package(url: "https://github.com/siteline/swiftui-introspect", from: "0.10.0"),
        .package(url: "https://github.com/saoudrizwan/Disk.git", from: "0.6.4"),
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.3.1"),
        .package(url: "https://github.com/colinc86/LaTeXSwiftUI", from: "1.3.2")
    ],
    targets: [
        .target(name: "ViewUtils",
                dependencies: [
                    .product(name: "SwiftUIIntrospect", package: "swiftui-introspect", condition: .when(platforms: [.iOS, .macCatalyst])),
                    .product(name: "MarkdownUI", package: "swift-markdown-ui", condition: .when(platforms: [.iOS, .macCatalyst])),
                    .product(name: "Disk", package: "Disk", condition: .when(platforms: [.iOS, .macCatalyst])),
                    .product(name: "LaTeXSwiftUI", package: "LaTeXSwiftUI", condition: .when(platforms: [.iOS, .macCatalyst]))
                ],
                path: "."),
    ]
)

// allow usage of regex literal

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

