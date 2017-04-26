import PackageDescription

#if os(Linux) && swift(>=3.1) && !swift(>=3.1.1)
print("Swift 3.1 not supported on Linux. Try Swift 3.0.2 or Swift >=3.1.1.")
#else
let package = Package(
    name: "KituraSMTP",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/BlueSSLService", majorVersion: 0, minor: 12),
        .Package(url: "https://github.com/IBM-Swift/BlueCryptor", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/IBM-Swift/LoggerAPI.git", majorVersion: 1)
    ]
)
#endif
