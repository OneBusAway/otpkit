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
            return "0.25 mile"
        case .halfMile:
            return "0.5 mile"
        case .oneMile:
            return "1 mile"
        case .twoMiles:
            return "2 miles"
        }
    }
    
    /// Distance in meters for API usage
    public var meters: Int {
        return self.rawValue
    }
    
    /// Accessibility description for VoiceOver
    public var accessibilityDescription: String {
        return "Maximum walking distance: \(title)"
    }
}
