//
//  OTPConfiguration.swift
//  OTPKit
//
//  Created by Manu on 2025-07-05.
//

import MapKit
import SwiftUI

/// Core configuration for OTPKit including server URL, transport modes, and UI theme.
/// The map provider must be supplied separately as OTPKit no longer hosts its own map view.
public struct OTPConfiguration {
    /// The OpenTripPlanner server API endpoint URL
    public let otpServerURL: URL

    /// Available transport modes for trip planning
    public let enabledTransportModes: [TransportMode]

    /// UI theme configuration
    public let themeConfiguration: OTPThemeConfiguration

    /// Geographic region for location search suggestions.
    /// Search results will be strictly limited to this region.
    public let searchRegion: MKCoordinateRegion

    public init(
        otpServerURL: URL,
        enabledTransportModes: [TransportMode] = TransportMode.allCases,
        themeConfiguration: OTPThemeConfiguration = OTPThemeConfiguration(),
        searchRegion: MKCoordinateRegion
    ) {
        self.otpServerURL = otpServerURL
        self.enabledTransportModes = enabledTransportModes
        self.themeConfiguration = themeConfiguration
        self.searchRegion = searchRegion
    }
}

// MARK: - Environment Key for Search Region

private struct OTPSearchRegionKey: EnvironmentKey {
    // Default to Seattle area for previews (matches existing PreviewHelpers coordinates)
    static let defaultValue = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
        latitudinalMeters: 50000,
        longitudinalMeters: 50000
    )
}

extension EnvironmentValues {
    public var otpSearchRegion: MKCoordinateRegion {
        get { self[OTPSearchRegionKey.self] }
        set { self[OTPSearchRegionKey.self] = newValue }
    }
}
