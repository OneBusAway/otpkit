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

/// The physical form factor of a rental vehicle, mirroring OTP's `FormFactor` GraphQL enum.
///
/// Decodes fail-open: an unrecognized wire value becomes `.other` instead of throwing,
/// so one novel vehicle type can never invalidate an entire multi-thousand-entity payload.
public enum VehicleFormFactor: String, Codable, Hashable, Sendable, CaseIterable {
    case bicycle = "BICYCLE"
    case cargoBicycle = "CARGO_BICYCLE"
    case car = "CAR"
    case moped = "MOPED"
    case scooter = "SCOOTER"
    case scooterSeated = "SCOOTER_SEATED"
    case scooterStanding = "SCOOTER_STANDING"
    case other = "OTHER"

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = VehicleFormFactor(rawValue: raw.normalizedOTPToken) ?? .other
    }

    /// True for any scooter variant (standing, seated, or unspecified).
    public var isScooter: Bool {
        switch self {
        case .scooter, .scooterSeated, .scooterStanding:
            return true
        case .bicycle, .cargoBicycle, .car, .moped, .other:
            return false
        }
    }

    /// True for any bicycle variant (including cargo bikes).
    public var isBicycle: Bool {
        switch self {
        case .bicycle, .cargoBicycle:
            return true
        case .scooter, .scooterSeated, .scooterStanding, .car, .moped, .other:
            return false
        }
    }
}
