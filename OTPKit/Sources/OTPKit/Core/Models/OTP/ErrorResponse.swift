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
import OSLog

/// `ErrorResponse` represents an error structure used across the application to handle and represent
/// OTP errors uniformly.
public struct ErrorResponse: Codable, Hashable {
    /// A unique identifier for the error.
    public let id: Int

    /// A descriptive message associated with the error, providing more detailed information about what went wrong.
    /// This message can be presented to the user or used in debugging to provide context about the error.
    public let message: String

    /// A message key identifying the error type.
    /// This value maps directly to a key in `Messages.properties` and can be used
    /// for control flow, localization, or client-side error mapping.
    public let messageCode: ErrorResponseCode

    public enum CodingKeys: String, CodingKey {
        case id
        case message = "msg"
        case messageCode = "message"
    }
}

public enum ErrorResponseCode: String, Codable, Hashable {
    case systemError = "SYSTEM_ERROR"
    case graphUnavailable = "GRAPH_UNAVAILABLE"
    case outsideBounds = "OUTSIDE_BOUNDS"
    case pathNotFound = "PATH_NOT_FOUND"
    case noTransitTimes = "NO_TRANSIT_TIMES"
    case requestTimeout = "REQUEST_TIMEOUT"
    case bogusParameter = "BOGUS_PARAMETER"
    case geocodeFromNotFound = "GEOCODE_FROM_NOT_FOUND"
    case geocodeToNotFound = "GEOCODE_TO_NOT_FOUND"
    case geocodeFromToNotFound = "GEOCODE_FROM_TO_NOT_FOUND"
    case tooClose = "TOO_CLOSE"
    case locationNotAccessible = "LOCATION_NOT_ACCESSIBLE"
    case geocodeFromAmbiguous = "GEOCODE_FROM_AMBIGUOUS"
    case geocodeToAmbiguous = "GEOCODE_TO_AMBIGUOUS"
    case geocodeFromToAmbiguous = "GEOCODE_FROM_TO_AMBIGUOUS"
    case underspecifiedTriangle = "UNDERSPECIFIED_TRIANGLE"
    case triangleNotAffine = "TRIANGLE_NOT_AFFINE"
    case triangleOptimizeTypeNotSet = "TRIANGLE_OPTIMIZE_TYPE_NOT_SET"
    case triangleValuesNotSet = "TRIANGLE_VALUES_NOT_SET"

    /// Fallback for unknown or future OTP message keys
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        if let known = ErrorResponseCode(rawValue: value) {
            self = known
        } else {
            Logger.main.warning("Unrecognized OTP error code: \(value)")
            self = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// Localization key used to resolve a user-facing message
    public var displayMessage: String {
        switch self {
        case .systemError:
            return OTPLoc("error.system_error")
        case .graphUnavailable:
            return OTPLoc("error.graph_unavailable")
        case .outsideBounds:
            return OTPLoc("error.outside_bounds")
        case .pathNotFound:
            return OTPLoc("error.path_not_found")
        case .noTransitTimes:
            return OTPLoc("error.no_transit_times")
        case .requestTimeout:
            return OTPLoc("error.request_timeout")
        case .bogusParameter:
            return OTPLoc("error.bogus_parameter")
        case .geocodeFromNotFound:
            return OTPLoc("error.geocode_from_not_found")
        case .geocodeToNotFound:
            return OTPLoc("error.geocode_to_not_found")
        case .geocodeFromToNotFound:
            return OTPLoc("error.geocode_from_to_not_found")
        case .tooClose:
            return OTPLoc("error.too_close")
        case .locationNotAccessible:
            return OTPLoc("error.location_not_accessible")
        case .geocodeFromAmbiguous:
            return OTPLoc("error.geocode_from_ambiguous")
        case .geocodeToAmbiguous:
            return OTPLoc("error.geocode_to_ambiguous")
        case .geocodeFromToAmbiguous:
            return OTPLoc("error.geocode_from_to_ambiguous")
        case .underspecifiedTriangle:
            return OTPLoc("error.underspecified_triangle")
        case .triangleNotAffine:
            return OTPLoc("error.triangle_not_affine")
        case .triangleOptimizeTypeNotSet:
            return OTPLoc("error.triangle_optimize_type_not_set")
        case .triangleValuesNotSet:
            return OTPLoc("error.triangle_values_not_set")
        case .unknown:
            return OTPLoc("error.unknown")
        }
    }
}
