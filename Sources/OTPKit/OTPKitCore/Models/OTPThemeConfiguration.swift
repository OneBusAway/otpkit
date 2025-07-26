//
//  OTPThemeConfiguration.swift
//  OTPKit
//
//  Created by Manu on 2025-07-05.
//

import SwiftUI
import UIKit

/// Theme configuration for customizing OTPKit UI appearance including colors and styling.
public struct OTPThemeConfiguration {
    public let primaryColor: Color
    public let secondaryColor: Color
    public let backgroundColor: Color
    public let textColor: Color
    public let cornerRadius: CGFloat

    public init(
        primaryColor: Color = .blue,
        secondaryColor: Color = .gray,
        backgroundColor: Color = Color(UIColor.systemBackground),
        textColor: Color = Color(UIColor.label),
        cornerRadius: CGFloat = 12
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.cornerRadius = cornerRadius
    }
}
