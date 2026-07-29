//
//  RouteBadge.swift
//  OTPKit
//
//  Created by Claude on 7/28/26.
//

import SwiftUI

/// The pill-shaped route identifier ("C Line", "2") drawn in the agency's route
/// color with a contrast-computed foreground, so a pale brand color still yields
/// a readable badge.
struct RouteBadge: View {
    let leg: Leg

    var body: some View {
        Text(leg.riderFacingRouteName)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 5))
            .foregroundStyle(foregroundColor)
    }

    private var backgroundColor: Color {
        leg.routeUIColor ?? Color(.systemGray2)
    }

    private var foregroundColor: Color {
        if let textColor = leg.routeTextUIColor {
            return textColor
        }
        return backgroundColor.isPerceptuallyLight ? .black : .white
    }
}

extension Color {
    /// True when black text has the higher WCAG contrast ratio against this
    /// color than white text does.
    var isPerceptuallyLight: Bool {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return false
        }
        func linearized(_ component: CGFloat) -> Double {
            let value = Double(component)
            return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
        // Contrast vs black is (L + 0.05) / 0.05; vs white it's 1.05 / (L + 0.05).
        // Black wins when (L + 0.05)² ≥ 0.05 × 1.05, i.e. L ≥ ~0.179.
        return (luminance + 0.05) * (luminance + 0.05) >= 0.05 * 1.05
    }
}
