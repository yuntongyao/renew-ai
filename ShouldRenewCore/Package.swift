// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShouldRenewCore",
    defaultLocalization: "zh-Hans",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ShouldRenewCore", targets: ["ShouldRenewCore"])
    ],
    targets: [
        .target(name: "ShouldRenewCore"),
        .testTarget(name: "ShouldRenewCoreTests", dependencies: ["ShouldRenewCore"])
    ]
)
