// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftSMTP",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftSMTP",
            targets: ["SwiftSMTP"]),
        ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/BlueSocket.git", from: "0.0.0"),
        .package(url: "https://github.com/IBM-Swift/BlueSSLService.git", from: "0.0.0"),
        .package(url: "https://github.com/IBM-Swift/BlueCryptor.git", from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/LoggerAPI.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target defines a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftSMTP",
            dependencies: ["Socket", "SSLService", "Cryptor", "LoggerAPI"]),
        .testTarget(
            name: "SwiftSMTPTests",
            dependencies: ["SwiftSMTP"]),
        ]
)
