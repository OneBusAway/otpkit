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

/// Represents a geographical location used in travel itineraries.
public struct Place: Codable, Hashable {
    /// Name or description of the place.
    public let name: String

    /// Longitude of the place.
    public let lon: Double

    /// Latitude of the place.
    public let lat: Double

    /// Type of vertex representing the place, such as 'NORMAL', 'STOP', or 'STATION'.
    public let vertexType: String
    
    ///StopId of the stop
    public let stopId: String?
    
    //StopCode of the stop
    public let stopCode: String?
    
    /// Custom initializer for creating Place instances
    public init(name: String,
                lon: Double,
                lat: Double,
                vertexType: String,
                stopId: String? = nil,
                stopCode: String? = nil) {
        self.name = name
        self.lon = lon
        self.lat = lat
        self.vertexType = vertexType
        self.stopId = stopId
        self.stopCode = stopCode
    }
}
