// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VinfoBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VinfoBar", targets: ["VinfoBar"]),
    ],
    targets: [
        .executableTarget(
            name: "VinfoBar",
            path: "Sources/VinfoBar"
        ),
        .testTarget(
            name: "VinfoBarTests",
            dependencies: ["VinfoBar"],
            path: "Tests/VinfoBarTests"
        ),
    ]
)