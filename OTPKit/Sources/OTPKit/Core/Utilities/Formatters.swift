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
            }
            else {
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

    static func formatDateToTime(_ date: Date, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
