// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Utils",
    platforms: [
        .iOS(.v16), .watchOS(.v9)
    ],
    products: [
        .library(name: "Utils", targets: ["Utils"]),
    ],
    dependencies: [
        .package(url: "https://github.com/saoudrizwan/Disk.git", from: "0.6.4")
    ],
    targets: [
        .target(name: "Utils", 
                dependencies: [.product(name: "Disk", package: "Disk", condition: .when(platforms: [.iOS, .macCatalyst]))],
                path: ".",
                resources: [.copy("demo.json")]),
    ]
)
