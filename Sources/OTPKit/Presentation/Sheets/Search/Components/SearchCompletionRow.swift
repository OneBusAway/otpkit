//
//  SearchCompletionRow.swift
//  OTPKit
//
//  Created by Manu on 2025-07-14.
//
import SwiftUI
import MapKit

struct SearchCompletionRow: View {
    let completion: MKLocalSearchCompletion
    let onTap: () -> Void
    let onFavoritesTap: (MKLocalSearchCompletion) -> Void

    @Environment(\.otpTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Location icon
                Image(systemName: iconForCompletion(completion))
                    .font(.system(size: 20))
                    .foregroundColor(theme.primaryColor)
                    .frame(width: 24)

                // Location details
                VStack(alignment: .leading, spacing: 2) {
                    Text(completion.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if !completion.subtitle.isEmpty {
                        Text(completion.subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(theme.secondaryColor)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Plus button for favorites
                Button(action: {
                    onFavoritesTap(completion)
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(theme.primaryColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func iconForCompletion(_ completion: MKLocalSearchCompletion) -> String {
        if completion.subtitle.lowercased().contains("airport") {
            return "airplane"
        } else if completion.subtitle.lowercased().contains("station") {
            return "train.side.front.car"
        } else if completion.subtitle.lowercased().contains("hospital") {
            return "cross.fill"
        } else if completion.subtitle.lowercased().contains("school") || completion.subtitle.lowercased().contains("university") {
            return "graduationcap.fill"
        } else if completion.subtitle.lowercased().contains("restaurant") || completion.subtitle.lowercased().contains("cafe") {
            return "fork.knife"
        } else if completion.subtitle.lowercased().contains("hotel") {
            return "bed.double.fill"
        } else {
            return "mappin.circle.fill"
        }
    }
}
