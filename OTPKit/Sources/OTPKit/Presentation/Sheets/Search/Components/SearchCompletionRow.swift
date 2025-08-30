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

                // Arrow icon
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func iconForCompletion(_ completion: MKLocalSearchCompletion) -> String {
        switch completion.subtitle.lowercased() {
        case let str where str.contains("airport"): return "airplane"
        case let str where str.contains("station"): return "train.side.front.car"
        case let str where str.contains("hospital"): return "cross.fill"
        case let str where str.contains("school"): return "graduationcap.fill"
        case let str where str.contains("university"): return "graduationcap.fill"
        case let str where str.contains("restaurant"): return "fork.knife"
        case let str where str.contains("cafe"): return "fork.knife"
        case let str where str.contains("hotel"): return "bed.double.fill"
        default: return "mappin.circle.fill"
        }
    }
}
