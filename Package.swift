// swift-tools-version:5.10
import PackageDescription

/// This list matches the [supported platforms on the Swift 5.10 release of SPM](https://github.com/swiftlang/swift-package-manager/blob/release/5.10/Sources/PackageDescription/SupportedPlatforms.swift#L34-L71)
/// Don't add new platforms here unless raising the swift-tools-version of this manifest.
let allPlatforms: [Platform] = [.macOS, .macCatalyst, .iOS, .tvOS, .watchOS, .visionOS, .driverKit, .linux, .windows, .android, .wasi, .openbsd]
let nonWASIPlatforms: [Platform] = allPlatforms.filter { $0 != .wasi }
let wasiPlatform: [Platform] = [.wasi]

let package = Package(
    name: "async-kit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(name: "AsyncKit", targets: ["AsyncKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.89.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.5"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.1.0"),
        .package(url: "https://github.com/PassiveLogic/swift-dispatch-async.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "AsyncKit",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOEmbedded", package: "swift-nio", condition: .when(platforms: nonWASIPlatforms)),
                .product(name: "NIOPosix", package: "swift-nio", condition: .when(platforms: nonWASIPlatforms)),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "DispatchAsync", package: "swift-dispatch-async", condition: .when(platforms: wasiPlatform))
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AsyncKitTests",
            dependencies: [
                .target(name: "AsyncKit"),
                .product(name: "NIOEmbedded", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    //.enableUpcomingFeature("DisableOutwardActorInference"),
    .enableUpcomingFeature("MemberImportVisibility"),
    //.enableExperimentalFeature("StrictConcurrency=complete"),
] }
