//
//  LocationRowView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-08.
//

import SwiftUI

struct LocationRowView: View {
    let location: Location
    var showHeart: Bool = false
    var showClock: Bool = false

    @Environment(\.otpTheme) private var theme

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            if showHeart {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                    .frame(width: 30)
            } else if showClock {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 30)
            } else {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 30)
            }

            // Location info
            VStack(alignment: .leading, spacing: 4) {
                Text(location.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if !location.title.isEmpty {
                    Text(location.title)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryColor)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.secondaryColor)
        }
        .padding(.vertical, 8)
    }
}
