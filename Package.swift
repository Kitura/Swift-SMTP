import PackageDescription

let package = Package(
    name: "KituraSMTP",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura", majorVersion: 1, minor: 7),
        .Package(url: "https://github.com/IBM-Swift/BlueCryptor", majorVersion: 0, minor: 8)
    ]
)
