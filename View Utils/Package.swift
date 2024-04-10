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
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.2")
    ],
    targets: [
        .target(name: "ViewUtils", dependencies: [
            .product(name: "SwiftUIIntrospect", package: "swiftui-introspect"),
            .product(name: "MarkdownUI", package: "swift-markdown-ui"), "Disk"], path: "."),
    ]
)
