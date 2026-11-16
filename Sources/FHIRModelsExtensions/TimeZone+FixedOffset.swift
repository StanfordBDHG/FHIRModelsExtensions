//
// This source file is part of the HealthKitOnFHIR open source project
//
// SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

public import Foundation


extension TimeZone {
    /// A time zone with a fixed offset from GMT, equal to the receiver's offset at the specified date.
    ///
    /// FHIRModels' `DateTime` and `Instant` store the time zone they are created with and serialize their GMT offset
    /// by looking up the offset for their local date and time in that zone. In the hour that repeats when daylight saving
    /// time ends, a local time occurs twice and the lookup resolves to the first occurrence. A date in the second occurrence
    /// is therefore written with the daylight saving offset, one hour earlier than it actually is.
    ///
    /// Creating FHIR date-times with the time zone returned by this function instead of a named time zone keeps
    /// the serialized offset tied to the date itself.
    ///
    /// - parameter date: The date whose GMT offset the returned time zone uses.
    /// - returns: A time zone whose offset is `secondsFromGMT(for: date)`, or the receiver if Foundation cannot represent that offset.
    public func fixedOffset(at date: Date) -> TimeZone {
        TimeZone(secondsFromGMT: secondsFromGMT(for: date)) ?? self
    }
}
