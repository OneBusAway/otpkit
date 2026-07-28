//
//  WalkingDistance.swift
//  OTPKit
//
//  Created by Manu on 2025-08-21.
//

import Foundation

/// Enum representing walking distance options for trip planning
public enum WalkingDistance: Int, CaseIterable, Sendable {
    case quarterMile = 402
    case halfMile = 805
    case oneMile = 1609
    case twoMiles = 3219

    /// Human-readable title for the walking distance
    public var title: String {
        switch self {
        case .quarterMile:
            return OTPLoc("walking_distance.quarter_mile", comment: "Walking distance option")
        case .halfMile:
            return OTPLoc("walking_distance.half_mile", comment: "Walking distance option")
        case .oneMile:
            return OTPLoc("walking_distance.one_mile", comment: "Walking distance option")
        case .twoMiles:
            return OTPLoc("walking_distance.two_miles", comment: "Walking distance option")
        }
    }

    /// Distance in meters for API usage
    public var meters: Int {
        return self.rawValue
    }

    /// Accessibility description for VoiceOver
    public var accessibilityDescription: String {
        return OTPLoc("walking_distance.accessibility",
                      comment: "VoiceOver description of the maximum walking distance setting",
                      title)
    }
}
