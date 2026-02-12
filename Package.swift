// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeySound",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "KeySound",
            path: "Sources/KeySound"
        )
    ]
)
