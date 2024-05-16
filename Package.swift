// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ContextuallyUniqueIdentifier",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "COID",
            targets: ["COID"]),
        .library(
            name: "AppUniqueIdentifier",
            targets: ["COID"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/RougeWare/Swift-Simple-Logging.git", from: "0.5.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "COID",
            dependencies: [
                .product(name: "SimpleLogging", package: "Swift-Simple-Logging"),
            ]),
        .testTarget(
            name: "ContextuallyUniqueIdentifierTests",
            dependencies: ["COID"]),
    ]
)
