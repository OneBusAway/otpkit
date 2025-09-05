//
//  OTPKitError.swift
//  OTPKit
//
//  Created by Manu on 2025-06-06.
//

import Foundation

/// Enum-based error handling system for type-safe error management
public enum OTPKitError: LocalizedError, Equatable {
    case tripPlanningFailed(String)
    case missingOriginOrDestination
    case apiError(String, statusCode: Int? = nil)

    // MARK: - Equatable
    public static func == (lhs: OTPKitError, rhs: OTPKitError) -> Bool {
        switch (lhs, rhs) {
        case (.missingOriginOrDestination, .missingOriginOrDestination):
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
        case .tripPlanningFailed(let details):
            return OTPLoc("error.trip_planning.message", comment: "Shown when trip planning fails", details)
        case .missingOriginOrDestination:
            return OTPLoc("error.missing_locations.message", comment: "Shown when origin or destination is missing")
        case .apiError(let message, _):
            return OTPLoc("error.api.message", comment: "Shown when API returns an error", message)
        }
    }

    /// Short titles for alert dialogs
    public var title: String {
        switch self {
        case .tripPlanningFailed, .missingOriginOrDestination:
            return OTPLoc("error.trip_planning.title", comment: "Title for trip planning errors")
        case .apiError:
            return OTPLoc("error.network.title", comment: "Title for network errors")
        }
    }

    /// Whether this error is recoverable with retry
    public var isRetryable: Bool {
        switch self {
        case .apiError, .tripPlanningFailed:
            return true
        case .missingOriginOrDestination:
            return false
        }
    }

    /// User-friendly message for UI display
    public var displayMessage: String {
        return self.errorDescription ?? OTPLoc("error.unknown", comment: "Shown when error description is nil")
    }
}
