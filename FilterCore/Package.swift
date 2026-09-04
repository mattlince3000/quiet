// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FilterCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FilterCore", targets: ["FilterCore"]),
    ],
    targets: [
        .target(
            name: "FilterCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "FilterCoreTests",
            dependencies: ["FilterCore"],
            resources: [.copy("Corpus")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
