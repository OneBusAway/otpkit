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
    let isSelected: Bool
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
                    .fill(backgroundColorValue)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }


    private var textColor: Color {
        isSelected ? Color(.systemBackground) : theme.secondaryColor
    }

    // Different background colors for selected, has location, and empty states
    private var backgroundColorValue: Color {
        if isSelected {
            return theme.primaryColor
        } else if hasLocation {
            return theme.primaryColor.opacity(0.25)
        } else {
            return Color(.systemGray6)
        }
    }

    private var strokeColor: Color {
        if isSelected {
            return theme.primaryColor.opacity(0.3)
        } else if hasLocation {
            return theme.primaryColor.opacity(0.2)
        } else {
            return Color.clear
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
            isSelected: true,
            hasLocation: true,
            action: {}
        )

        // Has location but not selected
        LocationButton(
            title: "Home",
            subtitle: "456 Oak Avenue",
            icon: "house.fill",
            isSelected: false,
            hasLocation: true,
            action: {}
        )

        // No location
        LocationButton(
            title: "Destination",
            subtitle: "Tap to set location",
            icon: "mappin",
            isSelected: false,
            hasLocation: false,
            action: {}
        )
    }
    .padding()
}
