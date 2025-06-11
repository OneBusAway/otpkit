//
//  ErrorTypes.swift
//  OTPKit
//
//  Created by Manu on 2025-06-06.
//

import Foundation

/// Enum-based error handling system for type-safe error management
/// Replaces scattered string-based error messages throughout the app
public enum OTPKitError: LocalizedError {
    // MARK: - Trip Planning Errors
    case tripPlanningFailed(String)
    case noRouteFound
    case invalidCoordinates
    case missingOriginOrDestination

    // MARK: - Location Errors
    case locationAccessDenied
    case locationUnavailable
    case geocodingFailed
    case invalidLocation

    // MARK: - Data Persistence Errors
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case dataCorrupted

    // MARK: - Network Errors
    case networkUnavailable
    case apiError(String)
    case invalidResponse
    case timeout

    // MARK: - User Input Errors
    case emptySearchQuery
    case invalidSearchQuery
    case noSearchResults

    /// User-friendly error descriptions
    public var errorDescription: String? {
        switch self {
            // Trip Planning
        case .tripPlanningFailed(let details):
            return "Failed to plan trip: \(details)"
        case .noRouteFound:
            return "No route found between selected locations"
        case .invalidCoordinates:
            return "Invalid location coordinates"
        case .missingOriginOrDestination:
            return "Please select both origin and destination"

            // Location
        case .locationAccessDenied:
            return "Location access denied. Please enable location services in Settings."
        case .locationUnavailable:
            return "Current location unavailable"
        case .geocodingFailed:
            return "Unable to determine location address"
        case .invalidLocation:
            return "Invalid location selected"

            // Data Persistence
        case .saveFailed(let item):
            return "Failed to save \(item)"
        case .loadFailed(let item):
            return "Failed to load \(item)"
        case .deleteFailed(let item):
            return "Failed to delete \(item)"
        case .dataCorrupted:
            return "Data appears to be corrupted"

            // Network
        case .networkUnavailable:
            return "Network connection unavailable"
        case .apiError(let message):
            return "Server error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .timeout:
            return "Request timed out"

            // User Input
        case .emptySearchQuery:
            return "Please enter a search term"
        case .invalidSearchQuery:
            return "Invalid search query"
        case .noSearchResults:
            return "No results found for your search"
        }
    }

    /// Short titles for alert dialogs
    public var title: String {
        switch self {
        case .tripPlanningFailed, .noRouteFound, .invalidCoordinates, .missingOriginOrDestination:
            return "Trip Planning Error"
        case .locationAccessDenied, .locationUnavailable, .geocodingFailed, .invalidLocation:
            return "Location Error"
        case .saveFailed, .loadFailed, .deleteFailed, .dataCorrupted:
            return "Data Error"
        case .networkUnavailable, .apiError, .invalidResponse, .timeout:
            return "Network Error"
        case .emptySearchQuery, .invalidSearchQuery, .noSearchResults:
            return "Search Error"
        }
    }
}
