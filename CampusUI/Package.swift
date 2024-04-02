// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CampusUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "CampusUI", targets: ["CampusUI"]),
    ], 
    dependencies: [
        .package(name: "FudanKit", path: "../Fudan Kit"),
        .package(name: "ViewUtils", path: "../View Utils")
    ],
    targets: [
        .target(name: "CampusUI", dependencies: ["FudanKit", "ViewUtils"]),
    ]
)
