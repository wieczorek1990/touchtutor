// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "TouchTutor",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v14),
    .iOS(.v26),
  ],
  targets: [
    .executableTarget(
      name: "TouchTutor",
      path: ".",
      exclude: [
        "Tests", "Docs", "bin", "macOS", "TouchTutor.xcodeproj",
        "Resources/LaunchScreen.storyboard",
      ],
      sources: ["Sources/TouchTutor"],
      resources: [
        .process("Resources"),
        .process("ScorePacks.storekit"),
      ],
      swiftSettings: [
        .enableUpcomingFeature("ApproachableConcurrency")
      ]
    ),
    .testTarget(name: "TouchTutorTests", dependencies: ["TouchTutor"]),
  ]
)
