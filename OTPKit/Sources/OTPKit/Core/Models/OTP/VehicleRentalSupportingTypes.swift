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

// Supporting types for vehicle rental entities. Field names match the
// GTFS GraphQL API exactly so these decode straight off the wire.

/// The rental system (GBFS feed) an entity belongs to, e.g. `lime_seattle`.
public struct RentalNetwork: Codable, Hashable, Sendable {
    public let networkId: String
    public let url: String?

    /// A rider-facing operator name derived from the network identifier:
    /// `lime_seattle` → "Lime", `bird-seattle-washington` → "Bird".
    public var displayName: String {
        let token = networkId
            .split(whereSeparator: { $0 == "_" || $0 == "-" })
            .first
            .map(String.init) ?? networkId
        return token.isEmpty ? networkId : token.capitalizedFirst
    }
}

/// GBFS deep-link URIs for opening an entity in the operator's app or website.
/// Frequently absent — the Seattle Lime feed publishes none.
public struct RentalUris: Codable, Hashable, Sendable {
    public let ios: String?
    public let android: String?
    public let web: String?
}

/// The kind of vehicle: form factor plus propulsion, e.g. bicycle + `ELECTRIC_ASSIST`.
public struct VehicleType: Codable, Hashable, Sendable {
    public let formFactor: VehicleFormFactor?
    public let propulsionType: String?

    /// True when the vehicle is powered (electric, electric-assist, combustion, etc.).
    public var isPowered: Bool {
        guard let propulsionType else { return false }
        return propulsionType.uppercased() != "HUMAN"
    }
}

/// Battery/fuel state of a vehicle. On some feeds (Seattle Lime) `percent` is
/// always nil while `range` is populated — never assume battery data exists.
public struct FuelInfo: Codable, Hashable, Sendable {
    /// Charge ratio in 0...1, when the feed provides it.
    public let percent: Double?
    /// Estimated remaining range in meters, when the feed provides it.
    public let range: Int?
}

/// Vehicles available at a station, optionally broken down by type.
public struct AvailableVehicles: Codable, Hashable, Sendable {
    public let total: Int?
    public let byType: [VehicleTypeCount]?
}

/// Docks/spaces available at a station.
public struct AvailableSpaces: Codable, Hashable, Sendable {
    public let total: Int?
}

/// A per-type availability count at a station.
public struct VehicleTypeCount: Codable, Hashable, Sendable {
    public let count: Int
    public let vehicleType: VehicleType
}
