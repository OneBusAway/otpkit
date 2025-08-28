//
//  FavoriteLocationCircle.swift
//  OTPKit
//
//  Created by Manu on 2025-08-28.
//

import SwiftUI

struct FavoriteLocationCircle: View {
    let location: Location
    let action: () -> Void

    @Environment(\.otpTheme) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Circular avatar
                ZStack {
                    Circle()
                        .fill(theme.primaryColor.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.primaryColor)
                }

                // Location title
                Text(location.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HStack(spacing: 16) {
        FavoriteLocationCircle(
            location: Location(
                title: "Home",
                subTitle: "123 Main Street",
                latitude: 0.0,
                longitude: 0.0
            )
        ) {
            // Preview action
        }

        FavoriteLocationCircle(
            location: Location(
                title: "Work Office",
                subTitle: "456 Business Ave",
                latitude: 0.0,
                longitude: 0.0
            )
        ) {
            // Preview action
        }
    }
    .padding()
}
