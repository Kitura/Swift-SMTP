import PackageDescription

#if os(Linux) && !swift(>=3.1.1)
fatalError("Please use Swift >=3.1.1.")
#else
let package = Package(
    name: "SwiftSMTP",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/BlueSocket.git", majorVersion: 0, minor: 12),
        .Package(url: "https://github.com/IBM-Swift/BlueSSLService.git", majorVersion: 0, minor: 12),
        .Package(url: "https://github.com/IBM-Swift/BlueCryptor", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/IBM-Swift/LoggerAPI.git", majorVersion: 1, minor: 7)
    ]
)
#endif
