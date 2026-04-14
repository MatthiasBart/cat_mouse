// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "server",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    .package(path: "../logic")
  ],
  targets: [
    .executableTarget(
      name: "server",
      dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOPosix", package: "swift-nio"),
        .product(name: "Logic", package: "logic")
      ],
      swiftSettings: swiftSettings
    )
  ]
)

var swiftSettings: [SwiftSetting] {
  [
    .enableUpcomingFeature("ExistentialAny")
  ]
}
