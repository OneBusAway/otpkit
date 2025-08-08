//
//  Formatters.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/5/24.
//

import SwiftUI

/// Reusable, commonly-used formatters for dates, durations, and distance.
class Formatters {
    static func formatTimeDuration(_ duration: Int) -> String {
        if duration < 60 {
            return "\(duration) second\(duration > 1 ? "s" : "")"
        }

        let (hours, minutes) = hoursAndMinutesFrom(seconds: duration)

        if hours == 0 {
            return String(format: "%d min", minutes)
        }

        return String(format: "%d hr %d min", hours, minutes)
    }

    static func hoursAndMinutesFrom(seconds: Int) -> (hours: Int, minutes: Int) {
        let hours = seconds / 3600
        let remainingSeconds = seconds % 3600
        let minutes = remainingSeconds / 60
        return (hours, minutes)
    }

    static func formatDistance(_ distance: Int) -> String {
        if distance < 1000 {
            return "\(distance) meters"
        } else {
            let miles = Double(distance) / 1609.34
            return String(format: "%.1f miles", miles)
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
