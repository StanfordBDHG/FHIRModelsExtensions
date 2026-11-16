//
// This source file is part of the HealthKitOnFHIR open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation
public import ModelsR4


extension Observation {
    /// Sets the `Observation`'s effective date.
    ///
    /// Each date is written with the GMT offset that `timeZone` has at that date,
    /// so that dates in the hour that repeats when daylight saving time ends keep their correct offset.
    /// See `TimeZone.fixedOffset(at:)`.
    @inlinable
    public mutating func setEffective(startDate: Date, endDate: Date, timeZone: TimeZone) throws {
        if startDate == endDate {
            effective = .dateTime(FHIRPrimitive(try DateTime(date: startDate, timeZone: timeZone.fixedOffset(at: startDate))))
        } else {
            effective = .period(Period(
                end: FHIRPrimitive(try DateTime(date: endDate, timeZone: timeZone.fixedOffset(at: endDate))),
                start: FHIRPrimitive(try DateTime(date: startDate, timeZone: timeZone.fixedOffset(at: startDate)))
            ))
        }
    }

    /// Sets the `Observation`'s issued date.
    ///
    /// The date is written with the GMT offset that `timeZone` has at that date. See `TimeZone.fixedOffset(at:)`.
    @inlinable
    public mutating func setIssued(on date: Date, timeZone: TimeZone = .current) throws {
        issued = FHIRPrimitive(try Instant(date: date, timeZone: timeZone.fixedOffset(at: date)))
    }
}
