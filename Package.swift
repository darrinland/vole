// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Vole",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Vole",
            path: "Sources/Vole"
        )
    ]
)
