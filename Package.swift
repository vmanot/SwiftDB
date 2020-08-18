// swift-tools-version:5.2

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
        .package(url: "https://github.com/vmanot/Data.git", .branch("master")),
        .package(url: "https://github.com/vmanot/Merge.git", .branch("master")),
        .package(url: "https://github.com/vmanot/Runtime.git", .branch("master")),
        .package(url: "https://github.com/vmanot/Swallow.git", .branch("master")),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", .branch("master"))
        
    ],
    targets: [
        .target(
            name: "SwiftDB",
            dependencies: [
                "Data",
                "Merge",
                "Runtime",
                "Swallow",
                "SwiftUIX"
            ],
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-Onone"])
            ]
        ),
        .testTarget(
            name: "SwiftDBTests",
            dependencies: ["SwiftDB"],
            path: "Tests"
        )
    ]
)
