// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SAV-E",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SAV-E",
            targets: ["SAVE"]
        ),
    ],
    dependencies: [
        // Privy iOS SDK for authentication
        .package(url: "https://github.com/privy-io/privy-ios.git", .upToNextMinor(from: "2.10.1")),
    ],
    targets: [
        .target(
            name: "SAVE",
            dependencies: [
                .product(name: "Privy", package: "privy-ios"),
            ],
            path: "SAV-E"
        ),
    ]
)
