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

/// A free-floating rental vehicle (dockless bike, scooter, etc.) — the dominant
/// entity type on real feeds.
public struct RentalVehicle: Codable, Hashable, Sendable {
    public let vehicleId: String
    /// Raw feed name. Often a placeholder like "Default vehicle type" — surface
    /// `VehicleRental.displayLabel` to riders instead.
    public let name: String
    public let lat: Double
    public let lon: Double
    public let allowPickupNow: Bool?
    public let operative: Bool?
    public let rentalNetwork: RentalNetwork?
    public let rentalUris: RentalUris?
    public let vehicleType: VehicleType?
    public let fuel: FuelInfo?

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Whether the vehicle is in service. Treats missing data as operative.
    public var isOperative: Bool {
        operative ?? true
    }

    /// True when the vehicle matches one of the given form factors.
    /// Fail-open: a vehicle with no typed data is assumed to match.
    public func matches(formFactors: Set<VehicleFormFactor>) -> Bool {
        guard let formFactor = vehicleType?.formFactor else { return true }
        return formFactors.contains(formFactor)
    }
}
