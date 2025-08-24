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
                    .foregroundColor(isSelected ? theme.primaryColor : theme.secondaryColor)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.secondaryColor)
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(hasLocation ? .primary : theme.secondaryColor)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? theme.primaryColor.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? theme.primaryColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
