// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CampusUI",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "CampusUI", targets: ["CampusUI"]),
    ],
    dependencies: [
        .package(name: "FudanKit", path: "../Fudan Kit"),
        .package(name: "ViewUtils", path: "../View Utils"),
        .package(name: "Utils", path: "../Utils"),
        .package(url: "https://github.com/stleamist/BetterSafariView.git", .upToNextMajor(from: "2.4.2")),
    ],
    targets: [
        .target(name: "CampusUI", dependencies: ["FudanKit", "ViewUtils", "Utils", "BetterSafariView"]),
    ]
)
