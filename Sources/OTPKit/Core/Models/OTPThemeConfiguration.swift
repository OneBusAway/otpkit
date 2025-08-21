//
//  OTPThemeConfiguration.swift
//  OTPKit
//
//  Created by Manu on 2025-07-05.
//

import SwiftUI

/// Theme configuration for customizing OTPKit UI appearance including colors and styling.
public struct OTPThemeConfiguration {
    public let primaryColor: Color
    public let secondaryColor: Color

    public init(
        primaryColor: Color = .blue,
        secondaryColor: Color = .gray
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
}

/// Environment key for accessing theme configuration in SwiftUI views
private struct OTPThemeConfigurationKey: EnvironmentKey {
    static let defaultValue = OTPThemeConfiguration()
}

extension EnvironmentValues {
    /// Access theme configuration from environment
    public var otpTheme: OTPThemeConfiguration {
        get { self[OTPThemeConfigurationKey.self] }
        set { self[OTPThemeConfigurationKey.self] = newValue }
    }
}
