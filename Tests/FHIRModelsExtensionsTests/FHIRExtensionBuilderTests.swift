//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import FHIRModelsExtensions
import Foundation
import ModelsR4
import Testing


/// Tests the extension builders, the date helpers, and the FHIR extension utilities under the value semantics of the FHIRModels types.
struct FHIRExtensionBuilderTests {
    private static let noteUrl = FHIRPrimitive(FHIRURI(stringLiteral: "https://bdh.stanford.edu/fhir/defs/testNote"))
    private static let otherUrl = FHIRPrimitive(FHIRURI(stringLiteral: "https://bdh.stanford.edu/fhir/defs/testOther"))
    
    /// An extension builder that writes its input into a string-valued extension, replacing any previous value.
    private static let noteBuilder = FHIRExtensionBuilder<String> { note, observation in
        observation.appendExtension(
            Extension(url: noteUrl, value: .string(note.asFHIRStringPrimitive())),
            replaceAllExistingWithSameUrl: true
        )
    }
    
    private static func note(_ value: String) -> Extension {
        Extension(url: noteUrl, value: .string(value.asFHIRStringPrimitive()))
    }
    
    private static func makeObservation() -> Observation {
        Observation(code: CodeableConcept(), status: FHIRPrimitive(.final))
    }
    
    
    @Test
    func typedExtensionBuilder() throws {
        var observation = Self.makeObservation()
        try observation.apply(Self.noteBuilder, input: "first")
        #expect(observation.extension == [Self.note("first")])
        
        try observation.apply(Self.noteBuilder, input: "second")
        #expect(observation.extension == [Self.note("second")])
        
        try Self.noteBuilder.apply(input: "third", to: &observation)
        #expect(observation.extension == [Self.note("third")])
    }
    
    
    @Test
    func typeErasedApplication() throws {
        var observation = Self.makeObservation()
        
        #expect(try Self.noteBuilder.apply(typeErasedInput: "typed", to: &observation))
        #expect(observation.extension == [Self.note("typed")])
        
        // an input of the wrong type must neither be applied nor modify the observation
        #expect(try !Self.noteBuilder.apply(typeErasedInput: 42, to: &observation))
        #expect(observation.extension == [Self.note("typed")])
        
        // a builder without input accepts any input
        let voidBuilder = FHIRExtensionBuilder { observation in
            observation.appendExtension(Extension(url: Self.otherUrl), replaceAllExistingWithSameUrl: true)
        }
        #expect(try voidBuilder.apply(typeErasedInput: 42, to: &observation))
        #expect(observation.extension == [Self.note("typed"), Extension(url: Self.otherUrl)])
        
        let erasedBuilders: [any FHIRExtensionBuilderProtocol] = [Self.noteBuilder, voidBuilder]
        for builder in erasedBuilders {
            try builder.apply(typeErasedInput: "erased", to: &observation)
        }
        // each builder replaced its own extension, which moves it to the end
        #expect(observation.extension == [Self.note("erased"), Extension(url: Self.otherUrl)])
    }
    
    
    @Test
    func builderOnlyModifiesTheTargetObservation() throws {
        var observation = Self.makeObservation()
        let untouched = observation
        try observation.apply(Self.noteBuilder, input: "note")
        #expect(observation.extension == [Self.note("note")])
        #expect(untouched.extension == nil)
        #expect(observation != untouched)
    }
    
    
    @Test
    func effectiveAndIssuedDates() throws {
        let timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let startDate = try #require(Calendar.current.date(from: .init(timeZone: timeZone, year: 2026, month: 3, day: 14, hour: 7)))
        let endDate = try #require(Calendar.current.date(byAdding: .minute, value: 15, to: startDate))
        
        var observation = Self.makeObservation()
        try observation.setEffective(startDate: startDate, endDate: startDate, timeZone: timeZone)
        #expect(observation.effective == .dateTime(FHIRPrimitive(try DateTime(date: startDate, timeZone: timeZone))))
        
        try observation.setEffective(startDate: startDate, endDate: endDate, timeZone: timeZone)
        #expect(observation.effective == .period(Period(
            end: FHIRPrimitive(try DateTime(date: endDate, timeZone: timeZone)),
            start: FHIRPrimitive(try DateTime(date: startDate, timeZone: timeZone))
        )))
        
        #expect(observation.issued == nil)
        try observation.setIssued(on: endDate)
        #expect(observation.issued == FHIRPrimitive(try Instant(date: endDate)))
    }
    
    
    @Test
    func absoluteTimeRangeExtension() throws {
        let startDate = try #require(Calendar.current.date(from: .init(year: 2026, month: 3, day: 14, hour: 7)))
        let endDate = try #require(Calendar.current.date(byAdding: .minute, value: 15, to: startDate))
        let start = Extension(
            url: FHIRExtensionUrls.absoluteTimeRangeStart,
            value: .decimal(startDate.timeIntervalSince1970.asFHIRDecimalPrimitive())
        )
        let end = Extension(
            url: FHIRExtensionUrls.absoluteTimeRangeEnd,
            value: .decimal(endDate.timeIntervalSince1970.asFHIRDecimalPrimitive())
        )
        let sameEnd = Extension(
            url: FHIRExtensionUrls.absoluteTimeRangeEnd,
            value: .decimal(startDate.timeIntervalSince1970.asFHIRDecimalPrimitive())
        )
        
        var observation = Self.makeObservation()
        observation.appendExtension(Self.note("keep"), replaceAllExistingWithSameUrl: false)
        
        // without an effective date, nothing is written
        try observation.encodeAbsoluteTimeRangeIntoExtension()
        #expect(observation.extension == [Self.note("keep")])
        
        // a single point in time yields identical start and end values
        try observation.setEffective(startDate: startDate, endDate: startDate, timeZone: .current)
        try observation.encodeAbsoluteTimeRangeIntoExtension()
        #expect(observation.extension == [Self.note("keep"), start, sameEnd])
        
        // encoding again replaces the previous values instead of duplicating them
        try observation.setEffective(startDate: startDate, endDate: endDate, timeZone: .current)
        try observation.encodeAbsoluteTimeRangeIntoExtension()
        #expect(observation.extension == [Self.note("keep"), start, end])
        #expect(observation.extensions(for: FHIRExtensionUrls.absoluteTimeRangeStart) == [start])
        #expect(observation.extensions(for: FHIRExtensionUrls.absoluteTimeRangeEnd) == [end])
        
        // an unsupported effective type is rejected, after the stale values were removed
        observation.effective = .timing(Timing())
        #expect(throws: (any Error).self) {
            try observation.encodeAbsoluteTimeRangeIntoExtension()
        }
        #expect(observation.extension == [Self.note("keep")])
    }
    
    
    @Test
    func extensionsOnElementsAndResources() throws {
        // extensions nested in an extension
        var parent = Extension(url: Self.otherUrl)
        parent.appendExtension(Self.note("a"), replaceAllExistingWithSameUrl: true)
        parent.appendExtension(Self.note("b"), replaceAllExistingWithSameUrl: true)
        #expect(parent.extension == [Self.note("b")])
        #expect(parent.extensions(for: Self.noteUrl) == [Self.note("b")])
        #expect(parent.extensions(for: Self.otherUrl).isEmpty)
        
        // extensions on a backbone element
        var component = ObservationComponent(code: CodeableConcept())
        component.appendExtensions([parent, Self.note("c")], replaceAllExistingWithSameUrl: false)
        #expect(component.extension == [parent, Self.note("c")])
        #expect(component.removeFirstExtension(withUrl: Self.noteUrl) == Self.note("c"))
        #expect(component.removeFirstExtension(withUrl: Self.noteUrl) == nil)
        #expect(component.removeAllExtensions(withUrl: Self.otherUrl) == [parent])
        #expect(component.extension == nil)
        
        // extensions on a domain resource other than an observation
        var questionnaire = Questionnaire(status: FHIRPrimitive(.active))
        #expect(questionnaire.removeAllExtensions(withUrl: Self.noteUrl) == nil)
        questionnaire.appendExtension(Self.note("q"), replaceAllExistingWithSameUrl: true)
        #expect(questionnaire.extensions(for: Self.noteUrl) == [Self.note("q")])
    }
    
    
    @Test
    func extensionsOnPrimitives() throws {
        var status: FHIRPrimitive<ObservationStatus> = FHIRPrimitive(.final)
        #expect(status.extensions(for: Self.noteUrl).isEmpty)
        status.appendExtension(Self.note("p"), replaceAllExistingWithSameUrl: true)
        status.appendExtension(Self.note("q"), replaceAllExistingWithSameUrl: true)
        #expect(status.extension == [Self.note("q")])
        
        var observation = Self.makeObservation()
        observation.status = status
        #expect(observation.status.extensions(for: Self.noteUrl) == [Self.note("q")])
        #expect(observation.status.removeAllExtensions(withUrl: Self.noteUrl) == [Self.note("q")])
        #expect(observation.status.extension == nil)
        #expect(status.extension == [Self.note("q")])
    }
    
    
    @Test
    func collectionKeyPathHelpers() throws {
        var observation = Self.makeObservation()
        #expect(observation.removeFirstElement(of: \.identifier) { _ in true } == nil)
        #expect(observation.removeAllElements(of: \.identifier) { _ in true } == nil)
        
        observation.appendElement(Identifier(id: "1"), to: \.identifier)
        observation.appendElements([Identifier(id: "2"), Identifier(id: "1")], to: \.identifier)
        observation.appendElements([], to: \.identifier)
        #expect(observation.identifier == [Identifier(id: "1"), Identifier(id: "2"), Identifier(id: "1")])
        
        #expect(observation.removeFirstElement(of: \.identifier) { $0.id == "1" } == Identifier(id: "1"))
        #expect(observation.identifier == [Identifier(id: "2"), Identifier(id: "1")])
        
        #expect(observation.removeAllElements(of: \.identifier) { $0.id == "1" } == [Identifier(id: "1")])
        #expect(observation.identifier == [Identifier(id: "2")])
        
        #expect(try #require(observation.removeAllElements(of: \.identifier) { _ in false }).isEmpty)
        #expect(observation.identifier == [Identifier(id: "2")])
        
        #expect(observation.removeAllElements(of: \.identifier) { _ in true } == [Identifier(id: "2")])
        #expect(observation.identifier == nil)
    }
}
