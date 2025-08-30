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

/// Represents a detailed step within a leg of an itinerary, providing navigation details.
public struct Step: Codable, Hashable {
    /// Distance of this step in meters.
    public let distance: Double

    /// Name of the street involved in this step.
    public let streetName: String

    /// Optional description of the direction to take at this step (e.g., "left", "right").
    public let relativeDirection: String?

    /// Optional elevation change during this step, in meters.
    public let elevationChange: Double?

    /// Longitude of the place.
    public let lon: Double

    /// Latitude of the place.
    public let lat: Double
}
