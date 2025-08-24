//
//  RoutePreference.swift
//  OTPKit
//
//  Created by Manu on 2025-08-21.
//

import Foundation

/// Enum representing route optimization preferences for trip planning
public enum RoutePreference: String, CaseIterable, Sendable {
    case fastestTrip = "fastest"
    case fewestTransfers = "transfers"
    
    /// Human-readable title for the route preference
    public var title: String {
        switch self {
        case .fastestTrip:
            return OTPLoc("route_preference.fastest_trip_title", comment: "Fastest trip route preference title")
        case .fewestTransfers:
            return OTPLoc("route_preference.fewest_transfers_title", comment: "Fewest transfers route preference title")
        }
    }
    
    /// Description explaining what this preference optimizes for
    public var description: String {
        switch self {
        case .fastestTrip:
            return OTPLoc("route_preference.fastest_trip_desc", comment: "Fastest trip route preference description")
        case .fewestTransfers:
            return OTPLoc("route_preference.fewest_transfers_desc", comment: "Fewest transfers route preference description")
        }
    }
    
    /// System icon name for this route preference
    public var iconName: String {
        switch self {
        case .fastestTrip:
            return "timer"
        case .fewestTransfers:
            return "arrow.triangle.swap"
        }
    }
    
    /// Accessibility description for VoiceOver
    public var accessibilityDescription: String {
        return "\(title): \(description)"
    }
}
