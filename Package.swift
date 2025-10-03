// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OTPKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OTPKit",
            targets: ["OTPKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/tevelee/SwiftUI-Flow.git", from: "3.1.0"),
        .package(url: "https://github.com/scenee/FloatingPanel.git", from: "3.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OTPKit",
            dependencies: [
                .product(name: "Flow", package: "SwiftUI-Flow"),
                .product(name: "FloatingPanel", package: "FloatingPanel")
            ],
            path: "OTPKit/Sources/OTPKit"
        ),
        .testTarget(
            name: "OTPKitTests",
            dependencies: ["OTPKit"],
            path: "OTPKit/Tests/OTPKitTests",
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
