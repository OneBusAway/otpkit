//
//  LocationOptionButton.swift
//  OTPKit
//
//  Created by Manu on 2025-07-08.
//

import SwiftUI

struct LocationOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.otpTheme) private var theme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(theme.secondaryColor)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.secondaryColor)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}
