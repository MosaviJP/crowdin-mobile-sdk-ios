// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CrowdinSDK",
    platforms: [
        .macOS(.v10_13),
        .watchOS(.v5),
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(name: "CrowdinSDK", targets: ["CrowdinSDK"])
    ],
    dependencies: [
        .package(url: "https://github.com/serhii-londar/BaseAPI.git", .upToNextMinor(from: "0.2.2"))
    ],
    targets: [
        .target(
            name: "CrowdinSDK",
            dependencies: ["BaseAPI"],
            path: "Sources/CrowdinSDK",
            exclude: [
                "Features",
                "Resources",
                "Settings"
            ],
            sources: [
                "CrowdinSDK",
                "CrowdinFileSystem",
                "CrowdinAPI",
                "Providers/Crowdin"
            ]
        )
    ]
)
