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

/// Represents a travel itinerary with detailed segments and timings.
public struct Itinerary: Codable, Hashable {
    /// Total duration of the itinerary in seconds.
    public let duration: Int

    /// Start time of the itinerary.
    public let startTime: Date

    /// End time of the itinerary.
    public let endTime: Date

    /// Total walking time in minutes within the itinerary.
    public let walkTime: Int

    /// Total transit time in minutes within the itinerary.
    public let transitTime: Int

    /// Total waiting time in minutes within the itinerary.
    public let waitingTime: Int

    /// Total walking distance in meters within the itinerary.
    public let walkDistance: Double

    /// Indicates whether the walking distance limit was exceeded.
    public let walkLimitExceeded: Bool

    /// Total elevation lost in meters within the itinerary.
    public let elevationLost: Double

    /// Total elevation gained in meters within the itinerary.
    public let elevationGained: Double

    /// Number of transfers within the itinerary.
    public let transfers: Int

    /// Array of `Leg` objects representing individual segments of the itinerary.
    public let legs: [Leg]

    public var summary: String {
        // TODO: localize this!
        let time = Formatters.formatDateToTime(startTime)
        let formattedDuration = Formatters.formatTimeDuration(duration)
        // return something like "43 minutes, departs at X:YY PM"
        return "Departs at \(time); duration: \(formattedDuration)"
    }
}
