// swift-tools-version: 5.9
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
            targets: ["OTPKit"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OTPKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "OTPKitTests",
            dependencies: ["OTPKit"],
            path: "Tests",
            resources: [
                // Copy Tests/ExampleTests/Resources directories as-is.
                // Use to retain directory structure.
                // Will be at top level in bundle.
                .process("Resources")
            ]
        )
    ]
)
