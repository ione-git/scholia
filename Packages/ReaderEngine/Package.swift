// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ReaderEngine",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "ReaderEngine", targets: ["ReaderEngine"])
    ],
    dependencies: [
        .package(url: "https://github.com/readium/swift-toolkit.git", exact: "3.9.0")
    ],
    targets: [
        .target(
            name: "ReaderEngine",
            dependencies: [
                .product(name: "ReadiumNavigator", package: "swift-toolkit"),
                .product(name: "ReadiumShared", package: "swift-toolkit"),
                .product(name: "ReadiumStreamer", package: "swift-toolkit"),
            ],
            resources: [.copy("Resources/reader.js"), .copy("Resources/page-count.js")],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        )
    ]
)
