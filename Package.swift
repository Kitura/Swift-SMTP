// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftSMTP",
    products: [
        .library(
            name: "SwiftSMTP",
            targets: ["SwiftSMTP"]),
        ],
    dependencies: [
        .package(url: "https://github.com/Kitura/BlueSocket.git", from: "1.0.0"),
        .package(url: "https://github.com/Kitura/BlueSSLService.git", from: "1.0.0"),
        .package(url: "https://github.com/Kitura/BlueCryptor.git", from: "1.0.0"),
        .package(url: "https://github.com/Kitura/LoggerAPI.git", from: "1.7.0"),
        ],
    targets: [
        .target(
            name: "SwiftSMTP",
            dependencies: ["Socket", "SSLService", "Cryptor", "LoggerAPI"]),
        .testTarget(
            name: "SwiftSMTPTests",
            dependencies: ["SwiftSMTP"]),
        ]
)
