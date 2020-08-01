// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SwiftDB",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "SwiftDB", targets: ["SwiftDB"])
    ],
    dependencies: [
        .package(url: "git@github.com:vmanot/Data.git", .branch("master")),
        .package(url: "git@github.com:vmanot/Runtime.git", .branch("master")),
        .package(url: "git@github.com:vmanot/Swallow.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "SwiftDB",
            dependencies: [
                "Data",
                "Runtime",
                "Swallow"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "SwiftDBTests",
            dependencies: ["SwiftDB"],
            path: "Tests"
        )
    ],
    swiftLanguageVersions: [
        .version("5.1")
    ]
)
