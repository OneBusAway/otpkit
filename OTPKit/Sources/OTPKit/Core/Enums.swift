//
//  Enums.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/31/25.
//

/// Enum to determine which direction leg view to display
public enum DirectionLegViewType {
    case vehicle
    case walk
    case unknown
}

public enum LocationMode {
    case origin
    case destination
}

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

/// Enum defining different overlay content types
public enum OverlayContentType {
    case loading
    case mapMarking
    case tripPlanner
    case originDestination
    case none
}

enum Sheet: Identifiable, Hashable {
    case tripResults
    case locationOptions(LocationMode)
    case directions
    case search(LocationMode)
    case advancedOptions

    var id: Int {
        var hasher = Hasher()
        hasher.combine(self)
        return hasher.finalize()
    }
}
