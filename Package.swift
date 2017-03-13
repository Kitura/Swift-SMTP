import PackageDescription

let package = Package(
    name: "KituraSMTP",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/BlueSSLService", majorVersion: 0, minor: 12)
    ]
)
