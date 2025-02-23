// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pastebin",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    products: [
        .executable(name: "pastebin", targets: ["pastebin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "7.0.0"),
        .package(url: "https://github.com/sloatescoan/hummingbird-macrorouting.git", from: "0.1.1"),
        .package(url: "https://github.com/sloatescoan/Templ.git", branch: "main"),
    ],
    targets: [
        .executableTarget(name: "pastebin",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdMacroRouting", package: "hummingbird-macrorouting"),
                .product(name: "Templ", package: "templ"),
                .product(name: "HummingbirdTempl", package: "templ"),
                .product(name: "SotoS3", package: "soto"),
            ],
            path: "Sources/App"
        ),
        // .testTarget(name: "pastebinTests",
        //     dependencies: [
        //         .byName(name: "pastebin"),
        //         .product(name: "HummingbirdTesting", package: "hummingbird")
        //     ],
        //     path: "Tests/AppTests"
        // )
    ]
)
