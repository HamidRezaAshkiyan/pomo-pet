// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PomoPet",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "PomoPetCore", targets: ["PomoPetCore"]),
        .executable(name: "PomoPet", targets: ["PomoPet"])
    ],
    targets: [
        .target(
            name: "PomoPetCore",
            resources: [
                .copy("Resources/sprites.json")
            ]
        ),
        .executableTarget(
            name: "PomoPet",
            dependencies: ["PomoPetCore"]
        ),
        .executableTarget(
            name: "PomoPetSelfTest",
            dependencies: ["PomoPetCore"]
        ),
        .testTarget(
            name: "PomoPetCoreTests",
            dependencies: ["PomoPetCore"]
        )
    ]
)
