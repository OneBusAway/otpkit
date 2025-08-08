//
//  TripMapMarkers.swift
//  OTPKit
//
//  Created by Manu on 2025-06-24.
//

import Foundation

/// Simple container for trip planning map markers
struct TripMapMarkers {
    var origin: MarkerItem?
    var destination: MarkerItem?

    /// Get all non-nil markers for map display
    var allMarkers: [MarkerItem] {
        [origin, destination].compactMap { $0 }
    }

    /// Reset both markers
    mutating func reset() {
        origin = nil
        destination = nil
    }

    /// Subscript for compatibility with OriginDestinationState
    subscript(state: OriginDestinationState) -> MarkerItem? {
        get {
            switch state {
            case .origin: return origin
            case .destination: return destination
            }
        }
        set {
            switch state {
            case .origin: origin = newValue
            case .destination: destination = newValue
            }
        }
    }
}
