// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "gen-unicode-data",
  platforms: [
    .macOS(.v10_15)
  ],
  targets: [
    .target(
      name: "gen-binary-props",
      dependencies: []
    )
  ]
)
