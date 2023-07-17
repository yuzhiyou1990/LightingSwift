// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LightningSwift",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LightningSwift",
            targets: ["LightningSwift"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/mxcl/PromiseKit.git", .upToNextMajor(from: "6.8.4")),
        .package(name: "Bech32", url: "https://github.com/lishuailibertine/Bech32", from: "1.0.5")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LightningSwift",
            dependencies: ["PromiseKit", "Bech32"]),
        .testTarget(
            name: "LightningSwiftTests",
            dependencies: ["LightningSwift"]),
    ]
)
