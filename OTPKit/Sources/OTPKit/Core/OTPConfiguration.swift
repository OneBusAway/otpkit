//
//  OTPConfiguration.swift
//  OTPKit
//
//  Created by Manu on 2025-07-05.
//

import MapKit
import SwiftUI

/// Core configuration for OTPKit including server URL, transport modes, map region, and UI theme.
public struct OTPConfiguration {
    /// The OpenTripPlanner server API endpoint URL
    public let otpServerURL: URL

    /// Initial map camera position and region
    public let region: MapCameraPosition

    /// Available transport modes for trip planning
    public let enabledTransportModes: [TransportMode]

    /// UI theme configuration
    public let themeConfiguration: OTPThemeConfiguration

    public init(
        otpServerURL: URL,
        enabledTransportModes: [TransportMode] = TransportMode.allCases,
        themeConfiguration: OTPThemeConfiguration = OTPThemeConfiguration(),
        region: MapCameraPosition
    ) {
        self.otpServerURL = otpServerURL
        self.enabledTransportModes = enabledTransportModes
        self.themeConfiguration = themeConfiguration
        self.region = region
    }
}
