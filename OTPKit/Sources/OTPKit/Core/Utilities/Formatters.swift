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
