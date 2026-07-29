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

/// A vehicle rental entity — either a docked station or a free-floating vehicle.
///
/// Decodes the GTFS GraphQL `RentalPlace` union using `__typename` discrimination.
/// `Decodable` only: these are read from responses and never serialized back.
public enum VehicleRental: Identifiable, Hashable, Sendable {
    case station(VehicleRentalStation)
    case vehicle(RentalVehicle)

    public var id: String {
        switch self {
        case .station(let station): return station.stationId
        case .vehicle(let vehicle): return vehicle.vehicleId
        }
    }

    // MARK: - Convenience Accessors

    /// The raw feed name. Prefer `displayLabel` for rider-facing UI.
    public var name: String {
        switch self {
        case .station(let station): return station.name
        case .vehicle(let vehicle): return vehicle.name
        }
    }

    public var coordinate: CLLocationCoordinate2D {
        switch self {
        case .station(let station): return station.coordinate
        case .vehicle(let vehicle): return vehicle.coordinate
        }
    }

    /// Whether the entity is in service. Treats missing data as operative.
    public var isOperative: Bool {
        switch self {
        case .station(let station): return station.isOperative
        case .vehicle(let vehicle): return vehicle.isOperative
        }
    }

    public var rentalNetwork: RentalNetwork? {
        switch self {
        case .station(let station): return station.rentalNetwork
        case .vehicle(let vehicle): return vehicle.rentalNetwork
        }
    }

    public var rentalUris: RentalUris? {
        switch self {
        case .station(let station): return station.rentalUris
        case .vehicle(let vehicle): return vehicle.rentalUris
        }
    }

    /// Battery charge ratio in 0...1, when the feed provides it. Frequently nil.
    public var batteryPercent: Double? {
        switch self {
        case .station: return nil
        case .vehicle(let vehicle): return vehicle.fuel?.percent
        }
    }

    /// True when the entity matches one of the given form factors (fail-open on
    /// missing typed data — see the underlying model's `matches(formFactors:)`).
    public func matches(formFactors: Set<VehicleFormFactor>) -> Bool {
        switch self {
        case .station(let station): return station.matches(formFactors: formFactors)
        case .vehicle(let vehicle): return vehicle.matches(formFactors: formFactors)
        }
    }

    // MARK: - Display Label

    /// A rider-facing label, e.g. "Lime e-bike" or "Pine St Station". Never surfaces
    /// known feed placeholders like "Default vehicle type".
    public var displayLabel: String {
        switch self {
        case .station(let station):
            return station.name

        case .vehicle(let vehicle):
            let typeName = Self.localizedTypeName(for: vehicle.vehicleType)

            if let network = vehicle.rentalNetwork?.displayName, !network.isEmpty {
                return "\(network) \(typeName)"
            }

            let trimmedName = vehicle.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty, !trimmedName.isRentalPlaceholderName {
                return trimmedName
            }

            return typeName.capitalizedFirst
        }
    }

    private static func localizedTypeName(for vehicleType: VehicleType?) -> String {
        guard let vehicleType, let formFactor = vehicleType.formFactor else {
            return OTPLoc("rental.vehicle_type.vehicle", comment: "Generic rental vehicle type name")
        }

        if formFactor.isBicycle {
            return vehicleType.isPowered
                ? OTPLoc("rental.vehicle_type.ebike", comment: "Rental vehicle type: electric bike")
                : OTPLoc("rental.vehicle_type.bike", comment: "Rental vehicle type: bike")
        }
        if formFactor.isScooter {
            return OTPLoc("rental.vehicle_type.scooter", comment: "Rental vehicle type: scooter")
        }

        switch formFactor {
        case .car:
            return OTPLoc("rental.vehicle_type.car", comment: "Rental vehicle type: car")
        case .moped:
            return OTPLoc("rental.vehicle_type.moped", comment: "Rental vehicle type: moped")
        default:
            return OTPLoc("rental.vehicle_type.vehicle", comment: "Generic rental vehicle type name")
        }
    }
}

// MARK: - Decodable

extension VehicleRental: Decodable {
    private enum TypeNameCodingKeys: String, CodingKey {
        case typename = "__typename"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TypeNameCodingKeys.self)
        let typename = try container.decode(String.self, forKey: .typename)

        switch typename {
        case "VehicleRentalStation":
            self = .station(try VehicleRentalStation(from: decoder))
        case "RentalVehicle":
            self = .vehicle(try RentalVehicle(from: decoder))
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown RentalPlace __typename: \(typename)"
            ))
        }
    }
}
