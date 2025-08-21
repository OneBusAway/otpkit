//
//  APIService.swift
//  OTPKit
//
//  Created by Manu on 2025-08-16.
//

import Foundation

/// Protocol defining the interface for trip planning API services
/// Enables plugin architecture supporting different backends (REST, GraphQL, etc.)
public protocol APIService {
    /// Fetches a trip plan from the API service
    /// - Parameter request: The trip planning request with origin, destination, and preferences
    /// - Returns: Response containing available trip itineraries
    func fetchPlan(_ request: TripPlanRequest) async throws -> OTPResponse
}

