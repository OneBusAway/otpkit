//
//  DateFormatterExtension.swift
//  OTPKit
//
//  Created by Manu on 2025-03-30.
//

import Foundation

extension DateFormatter {

    /// Builds a fixed-format formatter for OTP query parameters.
    ///
    /// The locale and calendar pins matter because a device set to a non-Gregorian calendar
    /// (Buddhist, Japanese Imperial) or a non-Latin numbering system otherwise emits
    /// parameters the server can't parse — `05-10-2567` instead of `05-10-2024`. This is the
    /// fixed-format guidance from Apple's Technical Q&A QA1480.
    private static func makeAPIFormatter(dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        // Setting the time zone explicitly, after `calendar`, is required: on iOS, dropping
        // this line makes the formatter emit UTC, shifting every request by the device's
        // offset and planning trips for the wrong local time. (Verified by A/B on the
        // simulator; the same experiment on macOS shows no difference, so don't "clean this
        // up" based on host-side behavior.) `LocalizationTests` pins the emitted value.
        //
        // It must be `.autoupdatingCurrent` rather than `.current`, because these formatters
        // are `static let` and outlive any time zone change. A rider who flies across a
        // boundary — or whose device picks up a new zone automatically — would otherwise keep
        // planning trips in the departure zone's offset until the app is relaunched. Unlike
        // the locale and calendar above, which are pinned deliberately for wire stability,
        // the zone is genuinely meant to follow the device.
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = dateFormat
        return formatter
    }

    /// Wire format for the OTP `date` query parameter. Not for display.
    static let tripDateFormatter: DateFormatter = makeAPIFormatter(dateFormat: "MM-dd-yyyy")

    /// Wire format for the OTP `time` query parameter. Not for display.
    ///
    /// The AM/PM overrides are kept from the original implementation so the emitted symbols
    /// can never drift with ICU data, even though `en_US_POSIX` supplies the same values today.
    static let tripTimeFormatter: DateFormatter = {
        let formatter = makeAPIFormatter(dateFormat: "h:mm a")
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()

    /// Wire format for 24-hour OTP times. Not for display.
    static let tripAPITimeFormatter: DateFormatter = makeAPIFormatter(dateFormat: "HH:mm")

}

extension Date {

    /// The date as an OTP `date` query parameter (`MM-dd-yyyy`). Not for display.
    var formattedTripDate: String {
        return DateFormatter.tripDateFormatter.string(from: self)
    }

    /// The time as an OTP `time` query parameter (`h:mm a`). Not for display.
    var formattedTripTime: String {
        return DateFormatter.tripTimeFormatter.string(from: self)
    }

}
