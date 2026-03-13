// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Utils",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16), .watchOS(.v9)
    ],
    products: [
        .library(name: "Utils", targets: ["Utils"]),
    ],
    dependencies: [
        .package(url: "https://github.com/saoudrizwan/Disk.git", from: "0.6.4"),
        .package(url: "https://github.com/kean/Pulse.git", from: "5.1.4")
    ],
    targets: [
        .target(name: "Utils", 
                dependencies: [
                    .product(name: "Disk", package: "Disk", condition: .when(platforms: [.iOS, .macCatalyst])),
                    .product(name: "Pulse", package: "Pulse", condition: .when(platforms: [.iOS, .macCatalyst]))
                ],
                path: ".",
                resources: [.copy("App/demo.json")]),
    ]
)
