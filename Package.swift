// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceInk",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1"),
    ],
    targets: [
        .executableTarget(
            name: "VoiceInk",
            dependencies: [
                "WhisperKit",
                "HotKey",
            ],
            path: "VoiceInk",
            exclude: ["Resources/Info.plist", "Resources/VoiceInk.entitlements"]
        ),
    ]
)
