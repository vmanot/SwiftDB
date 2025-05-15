// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "SwiftDB",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "SwiftDB",
            targets: [
                "SwiftDB"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/CorePersistence.git", branch: "main"),
        .package(url: "https://github.com/vmanot/Merge.git", branch: "master"),
        .package(url: "https://github.com/vmanot/SwiftAPI.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master"),
        // .package(path: "../Swallow"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "SwiftDB",
            dependencies: [
                "CorePersistence",
                "Merge",
                "Swallow",
                "SwiftAPI",
                "SwiftUIX"
            ],
            path: "Sources/SwiftDB",
            swiftSettings: []
        ),
        .target(
            name: "UserDB",
            dependencies: [
                "SwiftDB"
            ],
            path: "Sources/UserDB",
            swiftSettings: []
        ),
        .testTarget(
            name: "SwiftDBTests",
            dependencies: ["SwiftDB"],
            path: "Tests"
        )
    ]
)
