// swift-tools-version:6.0

//
// This source file is part of the Stanford Spezi open source project
// 
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import class Foundation.ProcessInfo
import PackageDescription


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
        .package(url: "https://github.com/apple/FHIRModels.git", from: "0.7.0"),
        .package(url: "https://github.com/antlr/antlr4.git", from: "4.13.1")
    ],
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
            ]
        ),
        .target(
            name: "FHIRPathParser",
            dependencies: [
                .product(name: "Antlr4", package: "antlr4")
            ],
            exclude: [
                "ANTLUtils"
            ]
        ),
        .target(
            name: "FHIRQuestionnaires",
            dependencies: [
                .product(name: "ModelsR4", package: "FHIRModels")
            ],
            resources: [
                .copy("Resources/SkipLogicExample.json"),
                .copy("Resources/TextValidationExample.json"),
                .copy("Resources/ContainedValueSetExample.json"),
                .copy("Resources/NumberExample.json"),
                .copy("Resources/DateTimeExample.json"),
                .copy("Resources/PHQ-9.json"),
                .copy("Resources/GAD-7.json"),
                .copy("Resources/GCS.json"),
                .copy("Resources/IPSS.json"),
                .copy("Resources/FormExample.json"),
                .copy("Resources/MultipleEnableWhen.json"),
                .copy("Resources/ImageCapture.json"),
                .copy("Resources/SliderExample.json")
            ]
        ),
        .testTarget(
            name: "FHIRModelsExtensionsTests",
            dependencies: [
                "FHIRModelsExtensions", "FHIRQuestionnaires"
            ]
        ),
        .testTarget(
            name: "FHIRPathParserTests",
            dependencies: ["FHIRPathParser"]
        )
    ]
)
