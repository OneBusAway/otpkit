//
//  OTPConfiguration.swift
//  OTPKit
//
//  Created by Manu on 2025-07-05.
//
import MapKit
import SwiftUI

public struct OTPConfiguration {
    public let otpServerURL: URL
    public let region: MapCameraPosition
    public let enabledTransportModes: [TransportMode]
    public let themeConfiguration: OTPThemeConfiguration

    public init(
        otpServerURL: URL,
        enabledTransportModes: [TransportMode] = TransportMode.allCases,
        themeConfiguration: OTPThemeConfiguration = OTPThemeConfiguration(),
        maxRecentLocations: Int = 10,
        region: MapCameraPosition


    ) {
        self.otpServerURL = otpServerURL
        self.enabledTransportModes = enabledTransportModes
        self.themeConfiguration = themeConfiguration
        self.region = region
    }
}
