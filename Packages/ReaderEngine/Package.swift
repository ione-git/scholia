// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ReaderEngine",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "ReaderEngine", targets: ["ReaderEngine"])
    ],
    targets: [
        .target(name: "ReaderEngine")
    ]
)
