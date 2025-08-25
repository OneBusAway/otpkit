//
//  TransportModeButton.swift
//  OTPKit
//
//  Created by Manu on 2025-07-14.
//
import SwiftUI

struct TransportModeButton: View {
    let mode: TransportMode
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.otpTheme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 44, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? theme.primaryColor : Color(.systemGray6))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
