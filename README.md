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

- **Building resources:** `Observation` gains `appendCoding(_:)`, `appendCategory(_:)`, `appendComponent(_:)`, `appendIdentifier(_:)`, `setEffective(startDate:endDate:timeZone:)`, and `setIssued(on:)`. Generic keypath helpers append to and remove from any collection-typed property of any FHIR type.
- **FHIR extensions:** every type that carries extensions offers `extensions(for:)`, `appendExtension(_:replaceAllExistingWithSameUrl:)`, and removal by URL. `FHIRExtensionBuilder` packages extension logic into reusable, `Sendable` values that are applied to an `Observation` with a given input.
- **Dates and decimals:** conversions between Foundation and FHIR dates, times, and instants, plus `asFHIRDecimalPrimitiveSafe()`, which throws on infinite values instead of trapping.
- **Questionnaires:** access to contained value sets, and typed accessors for the rendering and validation extensions used by questionnaire renderers, such as item control, slider step, minimum and maximum values, regular expressions, and keyboard hints.

### FHIRQuestionnaires

Ready-to-use `Questionnaire` resources: the PHQ-9, GAD-7, IPSS, and GCS instruments, and examples that exercise skip logic, text validation, sliders, dates, image capture, and contained value sets.

### FHIRPathParser

Parses [FHIRPath](https://hl7.org/fhirpath/) expressions and evaluates the date arithmetic that questionnaire constraints use, for example `today() + 3 months`.


## Usage

```swift
import FHIRModelsExtensions
import ModelsR4

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


## Installation

The project can be added to your Xcode project or Swift Package using the [Swift Package Manager](https://github.com/apple/swift-package-manager).

**Xcode:** For an Xcode project, follow the instructions on [adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app).

**Swift Package:** You can follow the [Swift Package Manager documentation about defining dependencies](https://developer.apple.com/documentation/packagedescription/package/dependency) to add this project as a dependency to your Swift Package.


## License
This project is licensed under the MIT License. See [Licenses](https://github.com/StanfordBDHG/FHIRModelsExtensions/tree/main/LICENSES) for more information.


## Contributors
This project is developed as part of the Stanford Mussallem Center for Biodesign at Stanford University.
See [CONTRIBUTORS.md](https://github.com/StanfordBDHG/FHIRModelsExtensions/tree/main/CONTRIBUTORS.md) for a full list of all FHIRModelsExtensions contributors.

![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-light.png#gh-light-mode-only)
![Stanford Byers Center for Biodesign Logo](https://raw.githubusercontent.com/StanfordBDHG/.github/main/assets/biodesign-footer-dark.png#gh-dark-mode-only)
