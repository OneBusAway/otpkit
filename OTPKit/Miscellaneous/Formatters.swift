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
        } else if duration < 3600 {
            let minutes = Double(duration) / 60
            return String(format: "%.1f min", minutes)
        } else {
            let hours = Double(duration) / 3600
            return String(format: "%.1f hours", hours)
        }
    }

    static func formatDistance(_ distance: Int) -> String {
        if distance < 1000 {
            return "\(distance) meters"
        } else {
            let miles = Double(distance) / 1609.34
            return String(format: "%.1f miles", miles)
        }
    }

    static func formatBusSchedule(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"

        let formattedTime = dateFormatter.string(from: date)

        return "Bus scheduled at \(formattedTime)"
    }
}
