// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FudanUI",
    defaultLocalization: "en", 
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "FudanUI", targets: ["FudanUI"]),
    ],
    dependencies: [
        .package(name: "FudanKit", path: "../Fudan Kit"),
        .package(name: "ViewUtils", path: "../View Utils"),
        .package(name: "Utils", path: "../Utils"),
        .package(url: "https://github.com/stleamist/BetterSafariView.git", .upToNextMajor(from: "2.4.2")),
    ],
    targets: [
        .target(name: "FudanUI", dependencies: ["FudanKit", "ViewUtils", "Utils", "BetterSafariView"], path: ".", resources: [.copy("Preview")]),
    ]
)
