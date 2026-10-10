// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EnduranceOnboarding",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "EnduranceOnboarding", targets: ["EnduranceOnboarding"])
    ],
    targets: [
        .target(
            name: "EnduranceOnboarding",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "EnduranceOnboardingTests",
            dependencies: ["EnduranceOnboarding"]
        )
    ]
)
