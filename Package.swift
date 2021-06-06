// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "BottomSheet",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "BottomSheet",
            targets: ["BottomSheet"]),
    ],
    targets: [
        .target(
            name: "BottomSheet"),
    ]
)
