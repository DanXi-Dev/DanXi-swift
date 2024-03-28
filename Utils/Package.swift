// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Utils",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "Utils", targets: ["Utils"]),
    ],
    targets: [
        .target(name: "Utils"),
    ]
)
