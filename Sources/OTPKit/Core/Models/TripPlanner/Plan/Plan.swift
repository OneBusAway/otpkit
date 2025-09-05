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

// swiftlint:disable identifier_name

/// Represents a comprehensive travel plan containing multiple itineraries.
public struct Plan: Codable, Hashable {
    /// Date and time when the travel plan was generated.
    public let date: Date

    /// Starting point of the travel plan.
    public let from: Place

    /// Destination point of the travel plan.
    public let to: Place

    /// List of `Itinerary` objects providing different routing options within the travel plan.
    public let itineraries: [Itinerary]
}

// swiftlint:enable identifier_name
