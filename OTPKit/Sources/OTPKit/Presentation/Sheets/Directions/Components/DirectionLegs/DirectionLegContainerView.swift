//
//  DirectionLegContainerView.swift
//  OTPKit
//
//  Common container view that ensures consistent layout for all leg types
//

import SwiftUI

/// A common container view that ensures consistent layout alignment across all leg types.
/// Uses a two-column structure: fixed-width left column for icons/badges, flexible right column for content.
struct DirectionLegContainerView<LeftContent: View, RightContent: View>: View {
    let leftContent: LeftContent
    let rightContent: RightContent
    let iconWidth: CGFloat
    let spacing: CGFloat

    init(
        iconWidth: CGFloat = 40,
        spacing: CGFloat = 16,
        @ViewBuilder leftContent: () -> LeftContent,
        @ViewBuilder rightContent: () -> RightContent
    ) {
        self.iconWidth = iconWidth
        self.spacing = spacing
        self.leftContent = leftContent()
        self.rightContent = rightContent()
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            // Fixed-width left column for icons/badges
            leftContent
                .frame(width: iconWidth, height: 40)

            // Flexible right column for text content
            rightContent
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        DirectionLegContainerView {
            Image(systemName: "figure.walk")
                .font(.system(size: 24))
        } rightContent: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Walk to foo")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("328 ft, about 1m")
                    .foregroundStyle(.gray)
            }
        }

        DirectionLegContainerView {
            Text("955")
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundStyle(.white)
                .font(.caption)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } rightContent: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Board Route 955")
                    .font(.headline)
                Text("woot")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding()
}
