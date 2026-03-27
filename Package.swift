// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkService",
    platforms: [.iOS(.v16), .macCatalyst(.v16), .watchOS(.v9), .macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NetworkService",
            targets: ["NetworkService"]
        ),
        .library(
            name: "NetworkServiceDomain",
            targets: ["NetworkServiceDomain"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/alrzi/AsyncExtensions.git", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", from: "1.0.0"),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.57.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NetworkServiceDomain",
            dependencies: [
                .product(name: "AsyncExtensions", package: "AsyncExtensions")
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .target(
            name: "NetworkService",
            dependencies: [
                .product(name: "AsyncExtensions", package: "AsyncExtensions"),
                .target(name: "NetworkServiceDomain")
            ],
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .testTarget(
            name: "NetworkServiceTests",
            dependencies: [
                "NetworkService",
                "NetworkServiceDomain",
                .product(name: "AsyncExtensions", package: "AsyncExtensions"),
                .product(name: "Clocks", package: "swift-clocks")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
