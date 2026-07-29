//
//  InTripRailView.swift
//  OTPKit
//
//  Created by Claude on 7/28/26.
//

import SwiftUI

/// The progress rail: the whole trip as one vertical timeline of `RailRowView`s,
/// shown at the medium and large detents.
///
/// Two cursors drive it. `currentLeg` (from `TripProgress.phase`) advances only
/// with the clock; `focusedLeg` moves on tap and springs back via the
/// Back-to-now pill. Nothing the rider taps can change where they are.
struct InTripRailView: View {
    let trip: Trip
    let now: Date
    @Binding var focusedLegIndex: Int?
    /// Called when focus changes so the host can frame the leg on the map.
    let onFocusLeg: (Leg?) -> Void

    @Environment(\.otpTheme) private var theme
    @State private var isCurrentRowVisible = true

    private var progress: TripProgress {
        TripProgress(itinerary: trip.itinerary, now: now)
    }

    var body: some View {
        let progress = self.progress
        let rows = progress.rows
        let currentRowID = rows.first(where: { $0.state == .current })?.id

        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if progress.phase == .notStarted {
                        leaveBanner(progress)
                            .padding(.bottom, 18)
                    }

                    ForEach(rows) { row in
                        railRow(for: row, progress: progress)
                            .id(row.id)
                            .contentShape(Rectangle())
                            .onTapGesture { handleTap(on: row) }
                            .modifier(CurrentRowVisibilityReporter(
                                isCurrentRow: row.id == currentRowID,
                                isVisible: $isCurrentRowVisible
                            ))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .overlay(alignment: .bottom) {
                if showsBackToNow {
                    backToNowPill(progress) {
                        focusedLegIndex = nil
                        onFocusLeg(nil)
                        if let currentRowID {
                            withAnimation {
                                scrollProxy.scrollTo(currentRowID, anchor: .center)
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
            .onChange(of: currentRowID) { _, newValue in
                // Auto-advance scrolls the rail only while tethered; untethered,
                // the pill label updates instead and the rail stays put.
                guard focusedLegIndex == nil, let newValue else { return }
                withAnimation {
                    scrollProxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func railRow(for row: RailRow, progress: TripProgress) -> some View {
        let isFocused = row.legIndex != nil && row.legIndex == focusedLegIndex && row.state != .current

        RailRowView(
            time: row.kind.showsTime ? row.time : nil,
            timeProminent: row.state != .done,
            gutterDetail: gutterDetail(for: row),
            mark: mark(for: row),
            segment: segment(for: row, progress: progress),
            dimmed: row.state == .done
        ) {
            switch row.kind {
            case .walk(let index):
                WalkRowContent(
                    leg: progress.legs[index],
                    state: row.state,
                    isExpanded: row.state == .current || isFocused
                )
            case .board(let index):
                BoardRowContent(
                    progress: progress,
                    legIndex: index,
                    state: row.state,
                    isFocused: isFocused,
                    now: now
                )
            case .ride(let index):
                RideRowContent(progress: progress, legIndex: index)
            case .getOff(let index):
                GetOffRowContent(progress: progress, legIndex: index, state: row.state)
            case .arrive:
                ArriveRowContent()
            }
        }
    }

    private func gutterDetail(for row: RailRow) -> RailGutterDetail {
        if row.state == .current {
            return .now
        }
        if let status = row.status, row.state != .done, status != .scheduled || row.kind.isBoard {
            return .status(status)
        }
        return .none
    }

    private func mark(for row: RailRow) -> RailMark {
        switch (row.kind, row.state) {
        case (_, .current):
            return .now
        case (_, .done):
            return .done
        case (.arrive, _):
            return .destination
        case (.walk, _):
            return .ring(Color(.systemGray3))
        case (.board(let index), _), (.getOff(let index), _), (.ride(let index), _):
            return .ring(progress.legs[index].routeUIColor ?? Color(.systemGray2))
        }
    }

    /// The segment below a row is fat and colored only while the span it covers
    /// is a ride still ahead of (or under) the rider.
    private func segment(for row: RailRow, progress: TripProgress) -> RailSegment {
        switch row.kind {
        case .arrive:
            return .none
        case .board(let index), .ride(let index):
            if row.state == .done, case .board = row.kind, !isRiding(index) {
                return .thin
            }
            return .bar(progress.legs[index].routeUIColor ?? Color(.systemGray2))
        case .walk, .getOff:
            return .thin
        }
    }

    private func isRiding(_ index: Int) -> Bool {
        if case .riding(let ridingIndex) = progress.phase { return ridingIndex == index }
        return false
    }

    // MARK: - Interactions

    private func handleTap(on row: RailRow) {
        guard let legIndex = row.legIndex else { return }
        if focusedLegIndex == legIndex {
            focusedLegIndex = nil
            onFocusLeg(nil)
        } else {
            focusedLegIndex = legIndex
            onFocusLeg(progress.legs[legIndex])
        }
    }

    private var showsBackToNow: Bool {
        guard progress.phase.legIndex != nil else { return false }
        return focusedLegIndex != nil || !isCurrentRowVisible
    }

    // MARK: - Chrome

    /// The pre-trip banner: "Leave in 4m" is the single most valuable thing a
    /// planner can say, and it's just the first leg's start time minus now.
    private func leaveBanner(_ progress: TripProgress) -> some View {
        NowCard {
            VStack(alignment: .leading, spacing: 5) {
                Text(OTPLoc("rail.leave_in_fmt",
                            comment: "Countdown until the rider must leave",
                            Formatters.formatTimeDuration(max(60, Int(progress.secondsUntilStart)))))
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(theme.primaryColor)

                Text(leaveInstruction(progress))
                    .font(.title3.weight(.semibold))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func leaveInstruction(_ progress: TripProgress) -> String {
        let startTime = Formatters.formatDateToTime(progress.legs.first?.startTime ?? trip.itinerary.startTime)
        if let firstLeg = progress.legs.first, firstLeg.transitLeg != true,
           let firstTransit = progress.legs.first(where: { $0.transitLeg == true }) {
            return OTPLoc("rail.start_walking_fmt",
                          comment: "Pre-trip instruction: when to start walking and which route it catches",
                          startTime, RailText.routeName(firstTransit))
        }
        return OTPLoc("rail.leave_at_fmt", comment: "Pre-trip instruction: when to leave", startTime)
    }

    private func backToNowPill(_ progress: TripProgress, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(backToNowLabel(progress), systemImage: "arrow.up")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 17)
                .padding(.vertical, 11)
                .background(Color(.label).opacity(0.9), in: Capsule())
                .shadow(color: .black.opacity(0.28), radius: 9, y: 6)
        }
        .buttonStyle(.plain)
    }

    /// Back-to-now names the current leg, so it doubles as a status line for
    /// the state the rider left behind.
    private func backToNowLabel(_ progress: TripProgress) -> String {
        OTPLoc("rail.back_to_now_fmt",
               comment: "Button returning the rail to the rider's current step; argument names that step",
               currentActivityName(progress))
    }

    private func currentActivityName(_ progress: TripProgress) -> String {
        switch progress.phase {
        case .walking:
            return OTPLoc("rail.now_walking", comment: "The rider is currently walking")
        case .waiting(let index):
            return OTPLoc("rail.now_waiting_fmt",
                          comment: "The rider is waiting for this route",
                          RailText.routeName(progress.legs[index]))
        case .riding(let index):
            return OTPLoc("rail.now_riding_fmt",
                          comment: "The rider is aboard this route",
                          RailText.routeName(progress.legs[index]))
        case .notStarted, .arrived:
            return OTPLoc("rail.now_walking", comment: "The rider is currently walking")
        }
    }
}

private extension RailRow.Kind {
    var showsTime: Bool { true }

    var isBoard: Bool {
        if case .board = self { return true }
        return false
    }
}

/// Reports whether the current ("now") row is on screen; scrolling it away is
/// what breaks the tether and reveals the Back-to-now pill.
private struct CurrentRowVisibilityReporter: ViewModifier {
    let isCurrentRow: Bool
    @Binding var isVisible: Bool

    func body(content: Content) -> some View {
        if isCurrentRow {
            content.onScrollVisibilityChange(threshold: 0.1) { visible in
                isVisible = visible
            }
        } else {
            content
        }
    }
}
