//
//  RailRowView.swift
//  OTPKit
//
//  Created by Claude on 7/28/26.
//

import SwiftUI

/// The layout system of the in-trip panel: a three-column row of
/// time gutter · rail · content at 52 / 26 / flexible. Nothing else in the rail
/// is positioned, which is why long strings and XXL text never break it.
///
/// Past accessibility text sizes the 52pt gutter can't hold a time without
/// wrapping, so it moves inline above the content and the row drops to two
/// columns. The rail marks are untouched at every size.
/// What renders beneath the gutter time: nothing, the "now" marker, or a
/// real-time status line.
enum RailGutterDetail: Equatable {
    case none
    case now
    case status(RealTimeStatus)
}

struct RailRowView<Content: View>: View {
    let time: Date?
    let timeProminent: Bool
    /// Real-time status line under the gutter time, or the "now" marker.
    let gutterDetail: RailGutterDetail
    let mark: RailMark
    let segment: RailSegment
    let dimmed: Bool
    @ViewBuilder let content: () -> Content

    @Environment(\.otpTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Wide enough for "10:29 PM" at subheadline without wrapping; localized
    /// times that still exceed it scale down rather than break across lines.
    static var gutterWidth: CGFloat { 64 }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityLayout
            } else {
                standardLayout
            }
        }
        .opacity(dimmed ? 0.5 : 1)
        .accessibilityElement(children: .combine)
    }

    private var standardLayout: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .trailing, spacing: 2) {
                if let time {
                    Text(Formatters.formatDateToTime(time))
                        .font(.subheadline.weight(timeProminent ? .semibold : .regular))
                        .foregroundStyle(timeProminent ? Color.primary : Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                gutterDetailView
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: Self.gutterWidth, alignment: .trailing)

            RailMarkColumn(mark: mark, segment: segment, theme: theme)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var accessibilityLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            RailMarkColumn(mark: mark, segment: segment, theme: theme)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if let time {
                        Text(Formatters.formatDateToTime(time))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    gutterDetailView
                }
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 18)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var gutterDetailView: some View {
        switch gutterDetail {
        case .none:
            EmptyView()
        case .now:
            Text(OTPLoc("rail.now", comment: "Gutter marker for the rider's current position"))
                .font(.caption)
                .foregroundStyle(theme.primaryColor)
        case .status(let status):
            Text(status.localizedDescription)
                .font(.caption)
                .foregroundStyle(status.color)
        }
    }
}

/// The tinted card that wraps the current step's content — the only card in the
/// rail, so "where am I" is answerable at a glance.
struct NowCard<Content: View>: View {
    @Environment(\.otpTheme) private var theme
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(theme.primaryColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.primaryColor.opacity(0.35), lineWidth: 1.5)
        )
    }
}

/// The neutral dark outline for a row the rider tapped to inspect. Deliberately
/// not the theme color: "what I'm reading" never impersonates "where I am."
struct FocusedCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.label), lineWidth: 1.5)
        )
    }
}
