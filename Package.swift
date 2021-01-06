// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SwiftDB",
    platforms: [
        .iOS("14.0"),
        .macOS("11.0"),
        .tvOS("14.0"),
        .watchOS("7.0")
    ],
    products: [
        .library(name: "SwiftDB", targets: ["SwiftDB"])
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/API.git", .branch("master")),
        .package(url: "https://github.com/vmanot/Merge.git", .branch("master")),
        .package(url: "https://github.com/vmanot/Runtime.git", .branch("master")),
        .package(url: "https://github.com/vmanot/Swallow.git", .branch("master")),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", .branch("master")),
        
    ],
    targets: [
        .target(
            name: "SwiftDB",
            dependencies: [
                "API",
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
