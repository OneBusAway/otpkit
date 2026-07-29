/*
 * Copyright (C) Open Transit Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy at:
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/// A geographic bounding box using raw coordinates, keeping MapKit out of the
/// network layer. Hosts provide conveniences from `MKCoordinateRegion`/`MKMapRect`.
public struct VehicleRentalBoundingBox: Equatable, Sendable {
    public let minimumLatitude: Double
    public let maximumLatitude: Double
    public let minimumLongitude: Double
    public let maximumLongitude: Double

    public init(
        minimumLatitude: Double,
        maximumLatitude: Double,
        minimumLongitude: Double,
        maximumLongitude: Double
    ) {
        self.minimumLatitude = minimumLatitude
        self.maximumLatitude = maximumLatitude
        self.minimumLongitude = minimumLongitude
        self.maximumLongitude = maximumLongitude
    }
}
