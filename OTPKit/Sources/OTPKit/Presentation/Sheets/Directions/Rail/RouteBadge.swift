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
        Text(leg.route ?? leg.mode.capitalized)
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
    /// True when the color is light enough that black text reads better than white.
    var isPerceptuallyLight: Bool {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return false
        }
        // Relative luminance, WCAG coefficients.
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance > 0.6
    }
}
