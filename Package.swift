// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Grind",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Grind",
            targets: ["Grind"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Grind",
            path: "Sources"
        )
    ]
)
