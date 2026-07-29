//
//  Formatters.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/5/24.
//

import SwiftUI

/// Reusable, commonly-used formatters for dates, durations, and distance.
class Formatters {
    private static let shared = Formatters()

    // MARK: - Duration Formatting

    private lazy var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    static func formatTimeDuration(_ duration: Int) -> String {
        let components = DateComponents(second: duration)
        return shared.durationFormatter.string(from: components) ?? "?"
    }

    /// Formats a countdown for display, never showing less than one minute —
    /// "0s" is an answer no rider wants from a transit app.
    static func formatCountdown(_ seconds: TimeInterval) -> String {
        formatTimeDuration(max(60, Int(seconds)))
    }

    // MARK: - Distance Formatting

    private lazy var feetFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit

        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 0
        formatter.numberFormatter = numberFormatter

        return formatter
    }()

    private lazy var milesFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit

        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter = numberFormatter

        return formatter
    }()

    static func formatDistance(_ distance: Int) -> String {
        let locale = Locale.current
        let meters = Double(distance)

        // Check if locale uses imperial (US, UK, etc.)
        if locale.measurementSystem == .us {
            let feet = meters * 3.28084

            // Use feet for distances under 0.1 miles (~528 feet)
            if feet < 528.0 {
                let measurement = Measurement(value: feet, unit: UnitLength.feet)
                return shared.feetFormatter.string(from: measurement)
            } else {
                let miles = meters * 0.000621371
                let measurement = Measurement(value: miles, unit: UnitLength.miles)
                return shared.milesFormatter.string(from: measurement)
            }
        }

        // Metric: use meters or kilometers
        if meters < 1000 {
            let measurement = Measurement(value: meters, unit: UnitLength.meters)
            return shared.feetFormatter.string(from: measurement)  // No decimals
        } else {
            let km = meters / 1000
            let measurement = Measurement(value: km, unit: UnitLength.kilometers)
            return shared.milesFormatter.string(from: measurement)  // 1 decimal
        }
    }

    // MARK: - Time Formatting

    /// Built once: `DateFormatter` construction costs ~65x a reuse, and this runs per
    /// itinerary row and per transit leg while scrolling.
    ///
    /// Because it is built once and never rebuilt, the device settings are wired up as
    /// `autoupdatingCurrent`. A plain `DateFormatter` captures `Locale.current` and friends at
    /// init, so a rider who switches region or 24-hour time — or crosses a time zone — would
    /// keep seeing arrival times in the old format and offset until the app relaunched.
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // Order matters: assigning `locale` resets `calendar`, so set it first.
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static func formatDateToTime(_ date: Date) -> String {
        shared.timeFormatter.string(from: date)
    }
}
