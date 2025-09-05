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

import CoreLocation
import Foundation

// swiftlint:disable identifier_name

/// Represents a single segment or leg of a travel itinerary.
public struct Leg: Codable, Hashable {
    /// Start time of the leg.
    public let startTime: Date

    /// End time of the leg.
    public let endTime: Date

    /// Mode of transportation used in this leg (e.g., "BUS", "TRAIN").
    public let mode: String

    /// Optional route identifier for this leg.
    public let route: String?

    /// Optional name of the transportation agency for this leg.
    public let agencyName: String?

    /// Starting point of the leg.
    public let from: Place

    /// Ending point of the leg.
    public let to: Place

    /// A container for the polyline of this leg.
    public let legGeometry: LegGeometry

    /// Returns an array of `CLLocationCoordinate2D`s representing the geometry of this `Leg`.
    public func decodePolyline() -> [CLLocationCoordinate2D]? {
        OTPKit.decodePolyline(legGeometry.points)
    }

    /// Distance covered in this leg, in meters.
    public let distance: Double

    /// Optional flag indicating whether this leg involves transit.
    public let transitLeg: Bool?

    /// Duration of the leg in seconds.
    public let duration: Int

    /// Optional flag indicating if the leg details are based on real-time data.
    public let realTime: Bool?

    /// Optional list of street names traversed in this leg.
    public let streetNames: [String]?

    /// Optional flag indicating whether the leg involves a pathway.
    public let pathway: Bool?

    /// Optional detailed steps for navigating this leg.
    public let steps: [Step]?

    /// Optional head sign of the transit legs, bus and trams
    public let headsign: String?
}

// swiftlint:enable identifier_name
