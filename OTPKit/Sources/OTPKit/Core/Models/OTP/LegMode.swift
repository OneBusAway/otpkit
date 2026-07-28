//
//  LegMode.swift
//  OTPKit
//

import Foundation
import OSLog

/// The means of conveyance for a `Leg`, as reported by OTP.
///
/// OTP sends these as uppercase tokens (`CABLE_CAR`). Rendering the token directly leaks
/// English-shaped data into every locale, so callers should use ``displayName``.
public enum LegMode: String, CaseIterable, Sendable {
    case walk = "WALK"
    case bicycle = "BICYCLE"
    case car = "CAR"
    case bus = "BUS"
    case tram = "TRAM"
    case subway = "SUBWAY"
    case rail = "RAIL"
    case ferry = "FERRY"
    case cableCar = "CABLE_CAR"
    case gondola = "GONDOLA"
    case funicular = "FUNICULAR"
    case transit = "TRANSIT"
    case airplane = "AIRPLANE"
    case trolleybus = "TROLLEYBUS"
    case monorail = "MONORAIL"

    /// OTP tokens that don't match a case's raw value but mean the same thing.
    private static let aliases: [String: LegMode] = ["BIKE": .bicycle, "TRAIN": .rail]

    /// Creates a mode from an OTP token, tolerating casing, spaces, and the `BIKE`/`TRAIN` aliases.
    public init?(otpMode: String) {
        let normalized = otpMode.normalizedOTPToken
        guard let mode = LegMode(rawValue: normalized) ?? Self.aliases[normalized] else { return nil }
        self = mode
    }

    /// Localized name of the mode.
    ///
    /// The four modes that also exist as request-side ``TransportMode`` values reuse those
    /// translations rather than maintaining a second copy of the same four words.
    public var displayName: String {
        switch self {
        case .walk:
            return TransportMode.walk.displayName
        case .bicycle:
            return TransportMode.bike.displayName
        case .car:
            return TransportMode.car.displayName
        case .transit:
            return TransportMode.transit.displayName
        case .bus:
            return OTPLoc("leg_mode.bus", comment: "Travel mode: bus")
        case .tram:
            return OTPLoc("leg_mode.tram", comment: "Travel mode: tram or streetcar")
        case .subway:
            return OTPLoc("leg_mode.subway", comment: "Travel mode: subway or metro")
        case .rail:
            return OTPLoc("leg_mode.rail", comment: "Travel mode: train")
        case .ferry:
            return OTPLoc("leg_mode.ferry", comment: "Travel mode: ferry")
        case .cableCar:
            return OTPLoc("leg_mode.cable_car", comment: "Travel mode: cable car")
        case .gondola:
            return OTPLoc("leg_mode.gondola", comment: "Travel mode: aerial gondola")
        case .funicular:
            return OTPLoc("leg_mode.funicular", comment: "Travel mode: funicular")
        case .airplane:
            return OTPLoc("leg_mode.airplane", comment: "Travel mode: airplane")
        case .trolleybus:
            return OTPLoc("leg_mode.trolleybus", comment: "Travel mode: trolleybus")
        case .monorail:
            return OTPLoc("leg_mode.monorail", comment: "Travel mode: monorail")
        }
    }
}

public extension Leg {
    /// Localized name of this leg's mode, falling back to the raw OTP token when unrecognized.
    var modeDisplayName: String {
        guard let legMode = LegMode(otpMode: mode) else {
            Logger.main.warning("Unrecognized OTP leg mode: \(mode)")
            return mode.humanizedOTPToken
        }
        return legMode.displayName
    }
}
