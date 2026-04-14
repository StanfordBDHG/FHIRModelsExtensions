// swift-tools-version:6.2

//
// This source file is part of the Stanford Spezi open source project
// 
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import class Foundation.ProcessInfo
import PackageDescription

/// Whether the package should run SwiftLint as part of its build process.
///
/// Set this to `false` before committing any changes.
let enableSwiftLintPlugin = false


let package = Package(
    name: "FHIRModelsExtensions",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
        .tvOS(.v17),
        .macOS(.v14),
        .macCatalyst(.v17)
    ],
    products: [
        .library(name: "FHIRModelsExtensions", targets: ["FHIRModelsExtensions"]),
        .library(name: "FHIRPathParser", targets: ["FHIRPathParser"]),
        .library(name: "FHIRQuestionnaires", targets: ["FHIRQuestionnaires"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/FHIRModels.git", .upToNextMinor("0.8.0")),
        .package(url: "https://github.com/antlr/antlr4.git", from: "4.13.1")
    ] + swiftLintPackage,
    targets: [
        .target(
            name: "FHIRModelsExtensions",
            dependencies: [
                "FHIRPathParser",
                .product(name: "ModelsR4", package: "FHIRModels")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault")
            ],
            plugins: [] + swiftLintPlugin
        ),
        .target(
            name: "FHIRPathParser",
            dependencies: [
                .product(name: "Antlr4", package: "antlr4")
            ],
            exclude: [
                "ANTLUtils"
            ],
            plugins: [] + swiftLintPlugin
        ),
        .target(
            name: "FHIRQuestionnaires",
            dependencies: [
                .product(name: "ModelsR4", package: "FHIRModels")
            ],
            resources: [.process("Resources")],
            plugins: [] + swiftLintPlugin
        ),
        .testTarget(
            name: "FHIRModelsExtensionsTests",
            dependencies: [
                "FHIRModelsExtensions", "FHIRQuestionnaires"
            ],
            plugins: [] + swiftLintPlugin
        ),
        .testTarget(
            name: "FHIRPathParserTests",
            dependencies: ["FHIRPathParser"],
            plugins: [] + swiftLintPlugin
        )
    ]
)


// MARK: SwiftLint support

var swiftLintPlugin: [Target.PluginUsage] {
    if enableSwiftLintPlugin {
        [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
    } else {
        []
    }
}

var swiftLintPackage: [PackageDescription.Package.Dependency] {
    if enableSwiftLintPlugin {
        [.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins.git", from: "0.63.2")]
    } else {
        []
    }
}
