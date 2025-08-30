//
//  DateFormatterExtension.swift
//  OTPKit
//
//  Created by Manu on 2025-03-30.
//

import Foundation

extension DateFormatter {

    static let tripDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        return formatter
    }()

    static let tripTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()

    static let tripAPITimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

}

extension Date {

    /// Format date as "MM-dd-yyy"
    var formattedTripDate: String {
        return DateFormatter.tripDateFormatter.string(from: self)
    }

    /// Format time as "h:mm a"
    var formattedTripTime: String {
        return DateFormatter.tripTimeFormatter.string(from: self)
    }

}
