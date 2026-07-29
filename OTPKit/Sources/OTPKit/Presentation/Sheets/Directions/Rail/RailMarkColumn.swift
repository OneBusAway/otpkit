//
//  RailMarkColumn.swift
//  OTPKit
//
//  Created by Claude on 7/28/26.
//

import SwiftUI

/// The five marks of the rail vocabulary. Exactly one `.now` pip appears per trip.
enum RailMark: Equatable {
    /// Filled pip in the theme's primary color with a halo — where the rider is now.
    case now
    /// Small gray pip — a moment the rider has completed.
    case done
    /// Ring in the given color — a boarding or alighting point still ahead.
    case ring(Color)
    /// Solid dark pip — the final destination.
    case destination
}

/// The line drawn beneath a mark, down to the next row.
enum RailSegment: Equatable {
    /// No line; used on the final row.
    case none
    /// Thin gray line — walking or waiting.
    case thin
    /// Fat bar in the route color — riding a vehicle. Thickness says
    /// "you're on a vehicle", so the encoding survives color blindness.
    case bar(Color)
}

/// The 26pt center column of a rail row: a mark on top and a segment that
/// stretches to the row's full height.
struct RailMarkColumn: View {
    let mark: RailMark
    let segment: RailSegment
    var theme: OTPThemeConfiguration

    static let columnWidth: CGFloat = 26

    var body: some View {
        VStack(spacing: 3) {
            markView
                .padding(.top, 3)

            switch segment {
            case .none:
                Spacer(minLength: 0)
            case .thin:
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            case .bar(let color):
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: 6)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: Self.columnWidth)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var markView: some View {
        switch mark {
        case .now:
            Circle()
                .fill(theme.primaryColor)
                .frame(width: 15, height: 15)
                .background(
                    Circle()
                        .fill(theme.primaryColor.opacity(0.18))
                        .frame(width: 25, height: 25)
                )
        case .done:
            Circle()
                .fill(Color(.systemGray3))
                .frame(width: 10, height: 10)
        case .ring(let color):
            Circle()
                .stroke(color, lineWidth: 3)
                .background(Circle().fill(Color(.systemBackground)))
                .frame(width: 12, height: 12)
        case .destination:
            Circle()
                .fill(Color(.label))
                .frame(width: 15, height: 15)
        }
    }
}
