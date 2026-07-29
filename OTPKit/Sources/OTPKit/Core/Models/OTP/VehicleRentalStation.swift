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

import CoreLocation
import Foundation

/// A docked vehicle rental station with availability info.
///
/// Availability comes in two generations: the typed `availableVehicles`/`availableSpaces`
/// breakdowns, and the older flat `vehiclesAvailable`/`spacesAvailable` counts. Both are
/// nullable on the wire; use `bikesAvailableCount`/`docksAvailableCount` which prefer the
/// typed data and fall back to the flat counts.
public struct VehicleRentalStation: Codable, Hashable, Sendable {
    public let stationId: String
    public let name: String
    public let lat: Double
    public let lon: Double
    public let vehiclesAvailable: Int?
    public let spacesAvailable: Int?
    public let allowPickupNow: Bool?
    public let allowDropoffNow: Bool?
    public let operative: Bool?
    public let rentalNetwork: RentalNetwork?
    public let rentalUris: RentalUris?
    public let availableVehicles: AvailableVehicles?
    public let availableSpaces: AvailableSpaces?

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Vehicles available for pickup, preferring typed availability data.
    public var vehiclesAvailableCount: Int? {
        availableVehicles?.total ?? vehiclesAvailable
    }

    /// Docks available for dropoff, preferring typed availability data.
    public var docksAvailableCount: Int? {
        availableSpaces?.total ?? spacesAvailable
    }

    /// Whether the station is in service. Treats missing data as operative.
    public var isOperative: Bool {
        operative ?? true
    }

    /// True when the station stocks any vehicle matching one of the given form factors.
    /// Fail-open: a station with no typed availability breakdown is assumed to match.
    public func matches(formFactors: Set<VehicleFormFactor>) -> Bool {
        guard let byType = availableVehicles?.byType, !byType.isEmpty else {
            return true
        }

        return byType.contains { typeCount in
            guard let formFactor = typeCount.vehicleType.formFactor else { return true }
            return formFactors.contains(formFactor)
        }
    }
}
