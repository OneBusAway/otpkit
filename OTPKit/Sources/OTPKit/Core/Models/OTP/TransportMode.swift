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
        }
    }
}
