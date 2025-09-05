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

/// Contains parameters used to define the specifics of a request to the OpenTripPlanner API.
public struct RequestParameters: Codable, Hashable {
    /// The starting location for the travel plan, expressed in a string format, typically as coordinates.
    public let fromPlace: String

    /// The destination location for the travel plan, expressed in a string format, typically as coordinates.
    public let toPlace: String

    /// The preferred time for departure or arrival, depending on `arriveBy`.
    public let time: String

    /// The date of travel.
    public let date: String

    /// Travel modes included in the trip planning, such as "TRANSIT", "WALK".
    public let mode: String

    /// Indicates whether the `time` parameter refers to arrival time ("true") or departure time ("false").
    public let arriveBy: String

    /// Maximum walking distance the user is willing to walk, expressed in meters.
    public let maxWalkDistance: String

    /// Indicates whether the route should accommodate wheelchair access ("true" or "false").
    public let wheelchair: String
}
