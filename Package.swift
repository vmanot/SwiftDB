// swift-tools-version:5.7

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
        .library(name: "SwiftDB", targets: ["SwiftDB"])
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/API.git", branch: "master"),
        .package(url: "https://github.com/vmanot/CorePersistence.git", branch: "main"),
        .package(url: "https://github.com/vmanot/FoundationX.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Merge.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Runtime.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master"),
        
    ],
    targets: [
        .target(
            name: "SwiftDB",
            dependencies: [
                "API",
                "CorePersistence",
                "FoundationX",
                "Merge",
                "Runtime",
                "Swallow",
                "SwiftUIX"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "SwiftDBTests",
            dependencies: ["SwiftDB"],
            path: "Tests"
        )
    ]
)
