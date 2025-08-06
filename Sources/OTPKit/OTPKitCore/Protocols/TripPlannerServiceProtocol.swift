//
//  TripPlannerServiceProtocol.swift
//  OTPKit
//
//  Created by Manu on 2025-01-27.
//

import Foundation

/// Protocol for trip planning services
public protocol TripPlannerServiceProtocol: AnyObject {
    
    /// Fetches trip plan from the API using a TripPlanRequest
    /// - Parameter request: The trip plan request containing all necessary parameters
    /// - Returns: An OTPResponse object containing the trip plan
    /// - Throws: An error if the network request fails or the response is invalid
    func fetchPlan(request: TripPlanRequest) async throws -> OTPResponse
    
}
