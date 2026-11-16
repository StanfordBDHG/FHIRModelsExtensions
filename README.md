<!--
                  
This source file is part of the Stanford Spezi open source project

SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)

SPDX-License-Identifier: MIT
             
-->

# FHIRModelsExtensions

[![Build and Test](https://github.com/StanfordBDHG/FHIRModelsExtensions/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/StanfordBDHG/FHIRModelsExtensions/actions/workflows/build-and-test.yml)
[![codecov](https://codecov.io/gh/StanfordBDHG/FHIRModelsExtensions/branch/main/graph/badge.svg?token=X7BQYSUKOH)](https://codecov.io/gh/StanfordBDHG/FHIRModelsExtensions)
[![DOI](https://zenodo.org/badge/573230182.svg)](https://zenodo.org/badge/latestdoi/573230182)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordBDHG%2FFHIRModelsExtensions%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/StanfordBDHG/FHIRModelsExtensions)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FStanfordBDHG%2FFHIRModelsExtensions%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/StanfordBDHG/FHIRModelsExtensions)

Swift utilities for working with FHIR R4 resources from [apple/FHIRModels](https://github.com/apple/FHIRModels): helpers that make building and modifying resources concise, a builder API for [FHIR extensions](https://build.fhir.org/extensibility.html), questionnaire conveniences, and a FHIRPath parser for date expressions.


## What's Included

The package provides three products.

### FHIRModelsExtensions

Extends the FHIRModels R4 types:

- **Building resources:** `Observation` gains `appendCoding(_:)`, `appendCategory(_:)`, `appendComponent(_:)`, `appendIdentifier(_:)`, `setEffective(startDate:endDate:timeZone:)`, and `setIssued(on:timeZone:)`. Generic keypath helpers append to and remove from any collection-typed property of any FHIR type.
- **FHIR extensions:** every type that carries extensions offers `extensions(for:)`, `appendExtension(_:replaceAllExistingWithSameUrl:)`, and removal by URL. `FHIRExtensionBuilder` packages extension logic into reusable, `Sendable` values that are applied to an `Observation` with a given input.
- **Dates and decimals:** conversions between Foundation and FHIR dates, times, and instants, plus `asFHIRDecimalPrimitiveSafe()`, which throws on infinite values instead of trapping. `setEffective` and `setIssued` write each date with the GMT offset its time zone has at that date, so a date in the hour that repeats when daylight saving time ends is not shifted by an hour; use `TimeZone.fixedOffset(at:)` to build other FHIR date-times the same way.
- **Questionnaires:** access to contained value sets, and typed accessors for the rendering and validation extensions used by questionnaire renderers, such as item control, slider step, minimum and maximum values, regular expressions, and keyboard hints.

### FHIRQuestionnaires

Ready-to-use `Questionnaire` resources: the PHQ-9, GAD-7, IPSS, and GCS instruments, and examples that exercise skip logic, text validation, sliders, dates, image capture, and contained value sets.

### FHIRPathParser

Parses [FHIRPath](https://hl7.org/fhirpath/) expressions and evaluates the date arithmetic that questionnaire constraints use, for example `today() + 3 months`.


## Usage

```swift
import FHIRModelsExtensions
import Foundation
import ModelsR4

let endDate = Date()
let startDate = endDate.addingTimeInterval(-60)

var observation = Observation(code: CodeableConcept(), status: FHIRPrimitive(.final))
observation.appendCoding(Coding(code: "8867-4", display: "Heart rate", system: "http://loinc.org"))
try observation.setEffective(startDate: startDate, endDate: endDate, timeZone: .current)

let trackTimeZone = FHIRExtensionBuilder<TimeZone> { timeZone, observation in
    observation.appendExtension(
        Extension(url: "https://example.org/fhir/timeZone", value: .string(timeZone.identifier.asFHIRStringPrimitive())),
        replaceAllExistingWithSameUrl: true
    )
}
try observation.apply(trackTimeZone, input: .current)
```

The FHIRModels types are structs, so every helper that modifies a resource is `mutating` and extension builders receive their target `inout`.

The full API reference is available on the [Swift Package Index](https://swiftpackageindex.com/StanfordBDHG/FHIRModelsExtensions/documentation/fhirmodelsextensions).


## Installation

Add the package with the [Swift Package Manager](https://github.com/apple/swift-package-manager). In Xcode, follow [adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app). In a Swift package, add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/StanfordBDHG/FHIRModelsExtensions.git", from: "0.2.0")
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "FHIRModelsExtensions", package: "FHIRModelsExtensions")
        ]
    )
]
```

### Requirements

- Swift 6.2 or later.
- iOS 17, watchOS 10, tvOS 17, visionOS 1, macOS 14, or Mac Catalyst 17.
- [FHIRModels](https://github.com/apple/FHIRModels) 0.9.4 or later. FHIRModels 0.9 turned every model type into a struct, which is why 0.2.0 is a breaking release.

If your package still depends on FHIRModels 0.8, stay on the 0.1 releases with `.upToNextMinor(from: "0.1.2")`. A requirement of `from: "0.1.0"` also allows 0.2.0, so it only keeps resolving to 0.1.x for as long as your package caps FHIRModels below 0.9.


## License
This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordBDHG/FHIRModelsExtensions/tree/main/LICENSES) for more information.


## Contributors
This project is developed as part of the Stanford Mussallem Center for Biodesign at Stanford University.
See [CONTRIBUTORS.md](https://github.com/StanfordBDHG/FHIRModelsExtensions/tree/main/CONTRIBUTORS.md) for a full list of all FHIRModelsExtensions contributors.

![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-light.png#gh-light-mode-only)
![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-dark.png#gh-dark-mode-only)
