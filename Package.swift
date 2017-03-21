import PackageDescription

let package = Package(
    name: "KituraSMTP",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/BlueSSLService", majorVersion: 0, minor: 12),
        .Package(url: "https://github.com/IBM-Swift/BlueCryptor", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/onevcat/MimeType.git",  majorVersion: 1)
    ]
)
