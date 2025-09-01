//
//  LocationButton.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI

struct LocationButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let hasLocation: Bool
    let action: () -> Void

    @Environment(\.otpTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textColor)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textColor)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundValue)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var textColor: Color {
        if hasLocation {
            return Color(.systemBackground)
        } else {
            return Color(.label)
        }
    }

    // Different background colors for selected, has location, and empty states
    private var backgroundValue: Color {
        if hasLocation {
            return theme.primaryColor.opacity(0.6)
        } else {
            return Color(.secondarySystemBackground)
        }
    }

    private var strokeColor: Color {
        if hasLocation {
            return theme.primaryColor.opacity(0.2)
        } else {
            return theme.primaryColor.opacity(0.3)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        // Selected state
        LocationButton(
            title: "Current Location",
            subtitle: "123 Main Street",
            icon: "location.fill",
            hasLocation: true,
            action: {}
        )

        // Has location but not selected
        LocationButton(
            title: "Home",
            subtitle: "456 Oak Avenue",
            icon: "house.fill",
            hasLocation: true,
            action: {}
        )

        // No location
        LocationButton(
            title: "Destination",
            subtitle: "Tap to set location",
            icon: "mappin",
            hasLocation: false,
            action: {}
        )
    }
    .padding()
}
