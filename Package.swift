// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeechToText",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1"),
    ],
    targets: [
        .executableTarget(
            name: "SpeechToText",
            dependencies: [
                "WhisperKit",
                "HotKey",
            ],
            path: "SpeechToText",
            exclude: ["Resources/Info.plist", "Resources/SpeechToText.entitlements", "Resources/Assets.xcassets"]
        ),
    ]
)
