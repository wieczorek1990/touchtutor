// swift-tools-version: 6.4

import PackageDescription

let package = Package(
  name: "TouchTutor",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v26),
  ],
  targets: [
    .executableTarget(
      name: "TouchTutor",
      path: ".",
      exclude: [
        "Tests", "Docs", "bin", "TouchTutor.xcodeproj",
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
