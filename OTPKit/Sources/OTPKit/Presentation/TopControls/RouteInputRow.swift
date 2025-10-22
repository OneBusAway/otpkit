//
//  RouteInputRow.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 10/22/25.
//

import SwiftUI

/// A view that renders a "From" or "To" location picker for the trip planner.
struct RouteInputRow: View {
    @Environment(\.otpTheme) private var theme

    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let hasLocation: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(hasLocation ? .primary : theme.primaryColor)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.primaryColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RouteInputRow(icon: "location", iconColor: .primary, title: "To", subtitle: "Microsoft", hasLocation: true) {}
}
