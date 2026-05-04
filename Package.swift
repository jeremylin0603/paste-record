// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PasteRecord",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "PasteRecord", targets: ["PasteRecord"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "PasteRecord",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            path: "Sources/PasteRecord"
        )
    ]
)
