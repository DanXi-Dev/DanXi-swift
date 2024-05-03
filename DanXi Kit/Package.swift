// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DanXiKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "DanXiKit", targets: ["DanXiKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
    ],
    targets: [
        .target(name: "DanXiKit", dependencies: ["KeychainAccess", "SwiftyJSON"], path: "."),
    ]
)
