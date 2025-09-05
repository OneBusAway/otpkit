//
//  TimePreference.swift
//  OTPKit
//
//  Created by Manu on 2025-08-21.
//

import Foundation

/// Enum representing time preference options for trip planning
public enum TimePreference: String, CaseIterable, Sendable {
    case leaveNow = "now"
    case departAt = "depart"
    case arriveBy = "arrive"

    /// Human-readable title for the time preference
    public var title: String {
        switch self {
        case .leaveNow:
            return OTPLoc("time_preference.leave_now_title", comment: "Leave now time preference title")
        case .departAt:
            return OTPLoc("time_preference.depart_at_title", comment: "Depart at specific time preference title")
        case .arriveBy:
            return OTPLoc("time_preference.arrive_by_title", comment: "Arrive by specific time preference title")
        }
    }

    /// Description explaining what this preference means
    public var description: String {
        switch self {
        case .leaveNow:
            return OTPLoc("time_preference.leave_now_desc", comment: "Leave now time preference description")
        case .departAt:
            return OTPLoc("time_preference.depart_at_desc", comment: "Depart at specific time preference description")
        case .arriveBy:
            return OTPLoc("time_preference.arrive_by_desc", comment: "Arrive by specific time preference description")
        }
    }

    /// System icon name for this time preference
    public var iconName: String {
        switch self {
        case .leaveNow:
            return "clock"
        case .departAt:
            return "clock.arrow.2.circlepath"
        case .arriveBy:
            return "clock.badge.checkmark"
        }
    }

    /// Whether this preference requires time selection UI
    public var requiresTimeSelection: Bool {
        switch self {
        case .leaveNow:
            return false
        case .departAt, .arriveBy:
            return true
        }
    }

    /// Accessibility description for VoiceOver
    public var accessibilityDescription: String {
        return "\(title): \(description)"
    }
}
