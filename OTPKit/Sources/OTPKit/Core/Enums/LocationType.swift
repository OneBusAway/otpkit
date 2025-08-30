//
//  LocationType.swift
//  OTPKit
//
//  Created by Manu on 2025-06-05.
//

import Foundation

/// Enum-based location type system to replace string-based approach
/// This provides type safety and prevents runtime errors from typos
public enum LocationType: String, CaseIterable, Codable {
    case origin
    case destination

    /// Display name for UI
    public var displayName: String {
        switch self {
        case .origin:
            return "Origin"
        case .destination:
            return "Destination"
        }
    }

    /// Capitalized name for UI display
    public var capitalizedName: String {
        return displayName.capitalized
    }

    /// Key for storing in dictionaries or user defaults
    public var key: String {
        return rawValue
    }
}

// MARK: - Convenience Extensions

public extension LocationType {
    /// Toggle between origin and destination
    var opposite: LocationType {
        switch self {
        case .origin:
            return .destination
        case .destination:
            return .origin
        }
    }

    /// Icon name for SF Symbols
    var iconName: String {
        switch self {
        case .origin:
            return "paperplane.fill"
        case .destination:
            return "mappin"
        }
    }
}
