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
                "SwiftDB",
            ]
        ),
        .library(
            name: "_SwiftDataPrivate",
            targets: ["_SwiftDataPrivate"]
        ),
        .library(
            name: "_CoreDataPrivate",
            targets: ["_CoreDataPrivate"]
        ),
        .library(
            name: "CoreDataToolbox",
            targets: ["CoreDataToolbox"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/CorePersistence.git", branch: "main"),
        .package(url: "https://github.com/vmanot/Merge.git", branch: "master"),
        .package(url: "https://github.com/vmanot/SwiftAPI.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master"),
        .package(url: "https://github.com/pookjw/ellekit.git", branch: "main"), // to be removed
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
            name: "CoreDataToolbox",
            dependencies: [
                .product(name: "ellekit", package: "ellekit")
            ],
            cSettings: [
                .unsafeFlags(["-fobjc-weak", "-fno-objc-arc"])
            ],
            linkerSettings: [
                .linkedFramework("CoreData")
            ]
        ),
        .binaryTarget(
            name: "_SwiftDataPrivate",
            path: "Sources/_SwiftDataPrivate/_SwiftDataPrivate.xcframework"
        ),
        .binaryTarget(
            name: "_CoreDataPrivate",
            path: "Sources/_CoreDataPrivate/_CoreDataPrivate.xcframework"
        ),
        .testTarget(
            name: "SwiftDBTests",
            dependencies: ["SwiftDB"],
            path: "Tests"
        )
    ]
)
