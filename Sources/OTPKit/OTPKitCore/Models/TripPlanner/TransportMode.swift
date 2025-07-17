//
//  OTPTransportMode.swift
//  OTPKit
//
//  Created by Manu on 2025-07-05.
//

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

    /// Human-readable description of the transport mode
    public var displayName: String {
        switch self {
        case .transit:
            return "Transit"
        case .walk:
            return "Walk"
        case .bike:
            return "Bike"
        case .car:
            return "Drive"
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
}
