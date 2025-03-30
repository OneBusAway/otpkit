// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OTPKit",
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
    dependencies: [
        .package(url: "https://github.com/nalexn/ViewInspector.git", from: "0.10.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OTPKit"),
        .testTarget(
            name: "OTPKitTests",
            dependencies: [
                "OTPKit",
                .product(name: "ViewInspector", package: "ViewInspector")
            ],
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
