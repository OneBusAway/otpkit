//
//  OTPKitError.swift
//  OTPKit
//
//  Created by Manu on 2025-06-06.
//

import Foundation

/// Enum-based error handling system for type-safe error management
/// Replaces scattered string-based error messages throughout the app
public enum OTPKitError: LocalizedError, Equatable {
    // Trip Planning (the main ones)
    case noRouteFound
    case tripPlanningFailed(String)
    case missingOriginOrDestination
    case invalidCoordinates

    // Network (critical for API calls)
    case networkUnavailable
    case apiError(String, statusCode: Int? = nil)
    
    // MARK: - Equatable
    public static func == (lhs: OTPKitError, rhs: OTPKitError) -> Bool {
        switch (lhs, rhs) {
        case (.noRouteFound, .noRouteFound),
             (.missingOriginOrDestination, .missingOriginOrDestination),
             (.invalidCoordinates, .invalidCoordinates),
             (.networkUnavailable, .networkUnavailable):
            return true
        case let (.tripPlanningFailed(lhsMessage), .tripPlanningFailed(rhsMessage)):
            return lhsMessage == rhsMessage
        case let (.apiError(lhsMessage, lhsCode), .apiError(rhsMessage, rhsCode)):
            return lhsMessage == rhsMessage && lhsCode == rhsCode
        default:
            return false
        }
    }
}

extension OTPKitError {
    /// User-friendly error descriptions
    public var errorDescription: String? {
        switch self {
            // Trip planning
        case .noRouteFound:
            return NSLocalizedString("error.no_route.message", comment: "Shown when no transit routes are found")
        case .tripPlanningFailed(let details):
            return String(format: NSLocalizedString("error.trip_planning.message", comment: "Shown when trip planning fails"), details)
        case .missingOriginOrDestination:
            return NSLocalizedString("error.missing_locations.message", comment: "Shown when origin or destination is missing")
        case .invalidCoordinates:
            return NSLocalizedString("error.invalid_coordinates.message", comment: "Shown when coordinates are invalid")

            // Network
        case .networkUnavailable:
            return NSLocalizedString("error.network.message", comment: "Shown when network is unavailable")
        case .apiError(let message, _):
            return String(format: NSLocalizedString("error.api.message", comment: "Shown when API returns an error"), message)
        }
    }

    /// Short titles for alert dialogs
    public var title: String {
        switch self {
        case .noRouteFound, .tripPlanningFailed, .missingOriginOrDestination:
            return NSLocalizedString("error.no_route.title", comment: "Title for route not found errors")
        case .networkUnavailable, .apiError:
            return NSLocalizedString("error.network.title", comment: "Title for network errors")
        case .invalidCoordinates:
            return NSLocalizedString("error.invalid_coordinates.title", comment: "Title for coordinate errors")
        }
    }

    /// Whether this error is recoverable with retry
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .apiError:
            return true
        case .tripPlanningFailed, .noRouteFound:
            return true
        default:
            return false
        }
    }

    /// User-friendly message for UI display
    public var displayMessage: String {
        return self.errorDescription ?? NSLocalizedString("error.unknown", comment: "Shown when error description is nil")
    }
}
