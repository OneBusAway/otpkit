//
//  TripProgressBarView.swift
//  OTPKit
//
//  Created by Claude on 7/28/26.
//

import SwiftUI

/// The segmented trip progress bar shown at the tip detent. Segments are
/// proportional to leg duration; walking segments fill in the theme's primary
/// color, transit segments in their route color. It never resets mid-trip.
struct TripProgressBarView: View {
    let progress: TripProgress

    /// The leg the ‹ › stepper has focused, outlined so the two cursors are
    /// both visible in one control. Nil when tethered to now.
    var focusedLegIndex: Int?

    @Environment(\.otpTheme) private var theme

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 3) {
                ForEach(progress.segments, id: \.legIndex) { segment in
                    segmentView(segment)
                        .frame(width: max(8, (proxy.size.width - spacing(in: proxy.size.width)) * segment.widthFraction))
                }
            }
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }

    private func spacing(in totalWidth: CGFloat) -> CGFloat {
        CGFloat(max(0, progress.segments.count - 1)) * 3
    }

    private func segmentView(_ segment: TripProgress.Segment) -> some View {
        let fillColor: Color = {
            if segment.isTransit {
                return progress.legs[segment.legIndex].routeUIColor ?? theme.primaryColor
            }
            return theme.primaryColor
        }()

        return GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.systemGray4))
                Capsule()
                    .fill(fillColor)
                    .frame(width: proxy.size.width * segment.fillFraction)
            }
        }
        .frame(height: 5)
        .overlay {
            if segment.legIndex == focusedLegIndex {
                Capsule()
                    .stroke(Color(.label), lineWidth: 2)
                    .padding(-3)
            }
        }
    }
}
