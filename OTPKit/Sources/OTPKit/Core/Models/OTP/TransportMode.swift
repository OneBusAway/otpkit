//
//  TransportMode.swift
//  OTPKit
//
//  Created by Manu on 2025-07-05.
//

import Foundation

/// Represents different transportation modes available for trip planning
public enum TransportMode: String, CaseIterable, Codable {
    /// Public transit (bus, train, etc.)
    case transit = "TRANSIT"
    /// Walking
    case walk = "WALK"
    /// Bicycling
    case bike = "BIKE"
    /// Driving
    case car = "CAR"
    /// Rented bicycle/micromobility (bikeshare) without transit — "Bikeshare Only".
    /// The raw value is the OTP 1.x REST wire token; the GraphQL service translates
    /// it to `{mode: BICYCLE, qualifier: RENT}`.
    case bikeRental = "BICYCLE_RENT"
    /// Transit combined with rented micromobility — "Transit + Bikeshare". Unlike the
    /// other cases, the raw value is *not* a wire token: this mode only ever reaches a
    /// request expanded through `apiModes`, never as itself.
    case transitBikeRental = "TRANSIT_BICYCLE_RENT"

    /// Localized, human-readable description of the transport mode
    public var displayName: String {
        switch self {
        case .transit:
            return OTPLoc("transport_mode.transit", comment: "Transport mode: Transit")
        case .walk:
            return OTPLoc("transport_mode.walk", comment: "Transport mode: Walk")
        case .bike:
            return OTPLoc("transport_mode.bike", comment: "Transport mode: Bike")
        case .car:
            return OTPLoc("transport_mode.car", comment: "Transport mode: Car")
        case .bikeRental:
            return OTPLoc("transport_mode.bike_rental", comment: "Transport mode: Bikeshare Only")
        case .transitBikeRental:
            return OTPLoc("transport_mode.transit_bike_rental", comment: "Transport mode: Transit + Bikeshare")
        }
    }

    /// System image name for the transport mode
    public var systemImageName: String {
        switch self {
        case .transit:
            return "bus"
        case .walk:
            return "figure.walk"
        case .bike:
            return "bicycle"
        case .car:
            return "car"
        case .bikeRental:
            return "bicycle.circle"
        case .transitBikeRental:
            return "bicycle.circle.fill"
        }
    }

    /// Returns the appropriate transport modes for API requests
    /// Some UI modes like transit require multiple API modes (transit + walk)
    public var apiModes: [TransportMode] {
        switch self {
        case .transit:
            return [.transit, .walk]
        case .walk:
            return [.walk]
        case .bike:
            return [.bike, .walk]
        case .car:
            return [.car]
        case .bikeRental:
            return [.bikeRental, .walk]
        case .transitBikeRental:
            return [.transit, .walk, .bikeRental]
        }
    }

    /// True for modes that only work against a rental-capable backend
    /// (`apiService is VehicleRentalService`). The UI hides these otherwise.
    public var requiresVehicleRentalSupport: Bool {
        self == .bikeRental || self == .transitBikeRental
    }

    /// The primitive modes this mode puts on the wire. Composite UI modes
    /// (`.transitBikeRental`) expand to their `apiModes`; primitives are themselves.
    /// Both services serialize through this, so a composite's fabricated raw value
    /// can never leak into a request — no matter how the host built it.
    public var wireModes: [TransportMode] {
        self == .transitBikeRental ? apiModes : [self]
    }
}
