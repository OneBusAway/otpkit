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
import OSLog

// Internal wire types for the OTP 2.x GTFS GraphQL API `vehicleRentalsByBbox` query.
// The public rental models decode directly off the wire (their field names match the
// GraphQL schema), so only the payload wrappers are private.

struct GraphQLRentalsData: Decodable {
    let vehicleRentalsByBbox: [LenientRentalPlace]?

    /// The decoded rentals, with unrecognized union members dropped.
    var rentals: [VehicleRental] {
        vehicleRentalsByBbox?.compactMap(\.rental) ?? []
    }
}

/// Wraps one `RentalPlace` union element, tolerating unknown `__typename`s.
///
/// A union member OTP adds later must degrade to a skipped entry (logged), never abort
/// the surrounding multi-thousand-entity decode — the same fail-open convention as
/// `VehicleFormFactor`. Malformed entities of a *known* type still throw, so real
/// decode bugs surface in tests instead of vanishing.
struct LenientRentalPlace: Decodable {
    let rental: VehicleRental?

    private enum TypeNameCodingKeys: String, CodingKey {
        case typename = "__typename"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TypeNameCodingKeys.self)
        let typename = try container.decode(String.self, forKey: .typename)

        switch typename {
        case "VehicleRentalStation":
            rental = .station(try VehicleRentalStation(from: decoder))
        case "RentalVehicle":
            rental = .vehicle(try RentalVehicle(from: decoder))
        default:
            Logger.main.warning("Skipping unrecognized RentalPlace __typename: \(typename)")
            rental = nil
        }
    }
}
