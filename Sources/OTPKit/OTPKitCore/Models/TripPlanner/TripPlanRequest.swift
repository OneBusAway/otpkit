/*
 * Copyright (C) Open Transit Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import CoreLocation

/// Represents a request for trip planning with all necessary parameters
public struct TripPlanRequest: Codable, Hashable {
    /// The starting location coordinates
    public let origin: CLLocationCoordinate2D
    /// The destination location coordinates
    public let destination: CLLocationCoordinate2D
    /// The date of travel
    public let date: Date
    /// The time of travel
    public let time: Date
    /// The transportation modes to include in the trip planning
    public let transportModes: [TransportMode]
    /// The maximum walking distance in meters
    public let maxWalkDistance: Int
    /// Whether the route should be wheelchair accessible
    public let wheelchairAccessible: Bool
    /// Whether the time parameter refers to arrival time (true) or departure time (false)
    public let arriveBy: Bool
    
    /// Creates a new trip plan request
    /// - Parameters:
    ///   - origin: The starting location coordinates
    ///   - destination: The destination location coordinates
    ///   - date: The date of travel
    ///   - time: The time of travel
    ///   - transportModes: The transportation modes to include (defaults to transit and walk)
    ///   - maxWalkDistance: The maximum walking distance in meters (defaults to 1000)
    ///   - wheelchairAccessible: Whether the route should be wheelchair accessible (defaults to false)
    ///   - arriveBy: Whether the time parameter refers to arrival time (defaults to false)
    public init(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        date: Date,
        time: Date,
        transportModes: [TransportMode] = [.transit, .walk],
        maxWalkDistance: Int = 1000,
        wheelchairAccessible: Bool = false,
        arriveBy: Bool = false
    ) {
        self.origin = origin
        self.destination = destination
        self.date = date
        self.time = time
        self.transportModes = transportModes
        self.maxWalkDistance = maxWalkDistance
        self.wheelchairAccessible = wheelchairAccessible
        self.arriveBy = arriveBy
    }
    
    /// Converts the transport modes to the API string format
    public var transportModesString: String {
        transportModes.map { $0.rawValue }.joined(separator: ",")
    }
    
    /// Validates the request parameters
    /// - Returns: True if the request is valid, false otherwise
    public func isValid() -> Bool {
        // Validate coordinates
        guard origin.latitude >= -90 && origin.latitude <= 90,
              origin.longitude >= -180 && origin.longitude <= 180,
              destination.latitude >= -90 && destination.latitude <= 90,
              destination.longitude >= -180 && destination.longitude <= 180 else {
            return false
        }
        
        // Validate max walk distance
        guard maxWalkDistance > 0 else {
            return false
        }
        
        // Validate that at least one transport mode is selected
        guard !transportModes.isEmpty else {
            return false
        }
        
        return true
    }
    
    // MARK: - Hashable Implementation
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin.latitude)
        hasher.combine(origin.longitude)
        hasher.combine(destination.latitude)
        hasher.combine(destination.longitude)
        hasher.combine(date)
        hasher.combine(time)
        hasher.combine(transportModes)
        hasher.combine(maxWalkDistance)
        hasher.combine(wheelchairAccessible)
        hasher.combine(arriveBy)
    }
    
    public static func == (lhs: TripPlanRequest, rhs: TripPlanRequest) -> Bool {
        return lhs.origin.latitude == rhs.origin.latitude &&
               lhs.origin.longitude == rhs.origin.longitude &&
               lhs.destination.latitude == rhs.destination.latitude &&
               lhs.destination.longitude == rhs.destination.longitude &&
               lhs.date == rhs.date &&
               lhs.time == rhs.time &&
               lhs.transportModes == rhs.transportModes &&
               lhs.maxWalkDistance == rhs.maxWalkDistance &&
               lhs.wheelchairAccessible == rhs.wheelchairAccessible &&
               lhs.arriveBy == rhs.arriveBy
    }
}



// MARK: - CLLocationCoordinate2D Codable Extension

extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    /// Formats the coordinate as a string for API requests
    public var formattedForAPI: String {
        return String(format: "%.4f,%.4f", latitude, longitude)
    }
}
