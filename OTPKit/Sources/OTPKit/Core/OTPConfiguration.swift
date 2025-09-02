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

    public init(
        otpServerURL: URL,
        enabledTransportModes: [TransportMode] = TransportMode.allCases,
        themeConfiguration: OTPThemeConfiguration = OTPThemeConfiguration()
    ) {
        self.otpServerURL = otpServerURL
        self.enabledTransportModes = enabledTransportModes
        self.themeConfiguration = themeConfiguration
    }
}
