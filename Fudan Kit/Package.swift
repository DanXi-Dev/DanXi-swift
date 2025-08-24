// swift-tools-version: 5.10

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
        .package(url: "https://github.com/TakeScoop/SwiftyRSA", from: "1.8.0"),
        .package(path: "../Utils"),
    ],
    targets: [
        .regexTarget(name: "FudanKit", dependencies: ["SwiftSoup", "Utils", "KeychainAccess", "SwiftyJSON", "SwiftyRSA"], path: "."),
    ]
)

extension Target {
    static func regexTarget(name: String, dependencies: [Target.Dependency], path: String) -> Target {
        let target = target(name: name, dependencies: dependencies, path: path)
        if target.swiftSettings == nil {
            target.swiftSettings = []
        }
        target.swiftSettings?.append(.enableUpcomingFeature("BareSlashRegexLiterals"))
        return target
    }
}
