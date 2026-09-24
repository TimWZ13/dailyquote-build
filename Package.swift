// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Trigin6Quote",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Trigin6Quote",
            targets: ["Trigin6Quote"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Trigin6Quote",
            path: "Trigin6Quote",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
