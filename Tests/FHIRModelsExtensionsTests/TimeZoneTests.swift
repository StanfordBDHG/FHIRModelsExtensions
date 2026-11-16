//
// This source file is part of the HealthKitOnFHIR open source project
//
// SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@testable import FHIRModelsExtensions
import Foundation
import ModelsR4
import Testing


struct TimeZoneTests {
    /// On 2026-11-01, Los Angeles falls back from PDT (-07:00) to PST (-08:00) at 02:00 PDT, so 01:00–02:00 local time occurs twice.
    /// 08:30Z is 01:30 PDT (first occurrence), 09:30Z is 01:30 PST (second occurrence).
    static let fallBackFirstOccurrence = Date(timeIntervalSince1970: 1_793_521_800) // 2026-11-01T08:30:00Z
    static let fallBackSecondOccurrence = Date(timeIntervalSince1970: 1_793_525_400) // 2026-11-01T09:30:00Z


    /// Tests creating a `Period` instance using different time zones for start and end date.
    @Test
    func multiTimeZonePeriod() throws {
        let timeZoneLA = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let timeZoneDE = try #require(TimeZone(identifier: "Europe/Berlin"))
        
        // we're choosing this exact date bc at that point in time, LA was already in DST, while germany was not.
        let startDateLA = try #require(Calendar.current.date(from: .init(timeZone: timeZoneLA, year: 2025, month: 3, day: 14, hour: 7)))
        let startDateDE = try #require(Calendar.current.date(from: .init(timeZone: timeZoneDE, year: 2025, month: 3, day: 14, hour: 15)))
        let endDateLA = try #require(Calendar.current.date(from: .init(timeZone: timeZoneLA, year: 2025, month: 3, day: 14, hour: 7, minute: 30)))
        let endDateDE = try #require(Calendar.current.date(from: .init(timeZone: timeZoneDE, year: 2025, month: 3, day: 14, hour: 15, minute: 30)))
        
        #expect(try DateTime(date: startDateLA, timeZone: timeZoneLA).asNSDate() == DateTime(date: startDateDE, timeZone: timeZoneDE).asNSDate())
        
        #expect(try DateTime(date: endDateLA, timeZone: timeZoneLA).asNSDate() == DateTime(date: endDateDE, timeZone: timeZoneDE).asNSDate())
        
        let period1 = Period(
            end: FHIRPrimitive(try DateTime(date: startDateLA, timeZone: timeZoneLA)),
            start: FHIRPrimitive(try DateTime(date: endDateDE, timeZone: timeZoneDE))
        )
        let period2 = Period(
            end: FHIRPrimitive(try DateTime(date: startDateDE, timeZone: timeZoneDE)),
            start: FHIRPrimitive(try DateTime(date: endDateLA, timeZone: timeZoneLA))
        )
        
        #expect(try #require(period1.start?.value).asNSDate() == #require(period2.start?.value).asNSDate())
        #expect(try #require(period1.end?.value).asNSDate() == #require(period2.end?.value).asNSDate())
    }


    @Test
    func fixedOffset() throws {
        let timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        #expect(timeZone.fixedOffset(at: Self.fallBackFirstOccurrence).secondsFromGMT() == -7 * 3600)
        #expect(timeZone.fixedOffset(at: Self.fallBackSecondOccurrence).secondsFromGMT() == -8 * 3600)
        // A fixed-offset zone has the same offset at every date.
        let fixed = timeZone.fixedOffset(at: Self.fallBackSecondOccurrence)
        #expect(fixed.secondsFromGMT(for: Self.fallBackFirstOccurrence) == -8 * 3600)
    }


    /// Dates in the repeated hour keep their own offset and round-trip to the same instant.
    @Test
    func effectiveDateInRepeatedHour() throws {
        let timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var observation = Observation(code: CodeableConcept(), status: FHIRPrimitive(.final))

        for (date, expected) in [
            (Self.fallBackFirstOccurrence, "2026-11-01T01:30:00-07:00"),
            (Self.fallBackSecondOccurrence, "2026-11-01T01:30:00-08:00")
        ] {
            try observation.setEffective(startDate: date, endDate: date, timeZone: timeZone)
            guard case let .dateTime(dateTime) = observation.effective else {
                Issue.record("Expected a dateTime effective value")
                return
            }
            let value = try #require(dateTime.value)
            #expect(value.description == expected)
            #expect(try value.asNSDate() == date)
            #expect(try DateTime(expected).asNSDate() == date)
        }
    }


    /// A period spanning the transition gets a different offset for each endpoint.
    @Test
    func effectivePeriodAcrossFallBack() throws {
        let timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var observation = Observation(code: CodeableConcept(), status: FHIRPrimitive(.final))

        try observation.setEffective(startDate: Self.fallBackFirstOccurrence, endDate: Self.fallBackSecondOccurrence, timeZone: timeZone)
        guard case let .period(period) = observation.effective else {
            Issue.record("Expected a period effective value")
            return
        }
        let start = try #require(period.start?.value)
        let end = try #require(period.end?.value)
        #expect(start.description == "2026-11-01T01:30:00-07:00")
        #expect(end.description == "2026-11-01T01:30:00-08:00")
        #expect(try start.asNSDate() == Self.fallBackFirstOccurrence)
        #expect(try end.asNSDate() == Self.fallBackSecondOccurrence)
    }


    @Test
    func issuedDateInRepeatedHour() throws {
        let timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var observation = Observation(code: CodeableConcept(), status: FHIRPrimitive(.final))

        try observation.setIssued(on: Self.fallBackSecondOccurrence, timeZone: timeZone)
        let issued = try #require(observation.issued?.value)
        #expect(issued.description == "2026-11-01T01:30:00-08:00")
        #expect(try issued.asNSDate() == Self.fallBackSecondOccurrence)
    }
}
