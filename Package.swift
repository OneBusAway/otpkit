// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OTPKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "OTPKit",
            targets: ["OTPKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/tevelee/SwiftUI-Flow.git", from: "3.1.0"),
        .package(url: "https://github.com/nalexn/ViewInspector.git", from: "0.10.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OTPKit",
            dependencies: [
                .product(name: "Flow", package: "SwiftUI-Flow")
            ],
            path: "OTPKit/Sources"
        ),
        .testTarget(
            name: "OTPKitTests",
            dependencies: [
                "OTPKit",
                .product(name: "ViewInspector", package: "ViewInspector")
            ],
            path: "OTPKit/Tests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
