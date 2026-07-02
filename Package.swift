// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NextSet",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "NextSetCore", targets: ["NextSetCore"]),
        .library(name: "NextSetLiveActivity", targets: ["NextSetLiveActivity"]),
        .executable(name: "NextSetAppShell", targets: ["NextSetAppShell"]),
        .executable(name: "NextSetCoreSmoke", targets: ["NextSetCoreSmoke"])
    ],
    targets: [
        .target(name: "NextSetCore"),
        .target(
            name: "NextSetLiveActivity",
            path: "NextSetLiveActivity",
            exclude: ["Info.plist"]
        ),
        .executableTarget(
            name: "NextSetAppShell",
            dependencies: ["NextSetCore"],
            path: "NextSetApp",
            exclude: ["Info.plist"]
        ),
        .executableTarget(name: "NextSetCoreSmoke", dependencies: ["NextSetCore"])
    ]
)
