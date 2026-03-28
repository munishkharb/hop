// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Hop",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Hop",
            path: "Sources/Hop",
            exclude: ["Info.plist"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "HopTests",
            dependencies: ["Hop"],
            path: "Tests/HopTests"
        ),
    ]
)
