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
    let progress: TripProgress
    @Binding var focusedLegIndex: Int?

    @Environment(\.otpTheme) private var theme
    @State private var isCurrentRowVisible = true

    var body: some View {
        let rows = progress.rows
        let currentRowID = rows.first(where: { $0.state == .current })?.id

        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if progress.phase == .notStarted {
                        leaveBanner
                            .padding(.bottom, 18)
                    }

                    ForEach(rows) { row in
                        railRow(for: row)
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
                // Enough clearance that the floating Back-to-now pill never
                // covers the final Arrive row.
                .padding(.bottom, 72)
            }
            .overlay(alignment: .bottom) {
                if showsBackToNow {
                    backToNowPill {
                        focusedLegIndex = nil
                        if let currentRowID {
                            withAnimation {
                                scrollProxy.scrollTo(currentRowID, anchor: .center)
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
            .onAppear {
                // onChange never fires for the initial value, so a sheet opened
                // mid-trip needs its own jump to the current row.
                guard focusedLegIndex == nil, let currentRowID else { return }
                scrollProxy.scrollTo(currentRowID, anchor: .center)
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
    private func railRow(for row: RailRow) -> some View {
        let isFocused = row.legIndex != nil && row.legIndex == focusedLegIndex && row.state != .current

        RailRowView(
            time: row.time,
            timeProminent: row.state != .done,
            gutterDetail: gutterDetail(for: row),
            mark: mark(for: row),
            segment: segment(for: row),
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
                    isFocused: isFocused
                )
            case .ride(let index):
                RideRowContent(progress: progress, legIndex: index)
            case .getOff(let index):
                GetOffRowContent(progress: progress, legIndex: index, state: row.state)
            case .pickUpVehicle(let index):
                PickUpVehicleRowContent(
                    leg: progress.legs[index],
                    state: row.state,
                    isExpanded: row.state == .current || isFocused
                )
            case .rideRental(let index):
                RideRentalRowContent(progress: progress, legIndex: index)
            case .dropOffVehicle(let index):
                DropOffVehicleRowContent(progress: progress, legIndex: index, state: row.state)
            case .arrive:
                ArriveRowContent()
            }
        }
    }

    private func gutterDetail(for row: RailRow) -> RailGutterDetail {
        if row.state == .current {
            return .now
        }
        if let status = row.status, row.state != .done {
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
        case (.pickUpVehicle, _), (.rideRental, _), (.dropOffVehicle, _):
            return .ring(.otpRentalPurple)
        case (.board(let index), _), (.getOff(let index), _), (.ride(let index), _):
            return .ring(progress.legs[index].routeUIColor ?? Color(.systemGray2))
        }
    }

    /// The segment below a row is fat and colored only while the span it covers
    /// is a ride still ahead of (or under) the rider.
    private func segment(for row: RailRow) -> RailSegment {
        switch row.kind {
        case .arrive:
            return .none
        case .board(let index), .ride(let index):
            if row.state == .done, case .board = row.kind, !isRiding(index) {
                return .thin
            }
            return .bar(progress.legs[index].routeUIColor ?? Color(.systemGray2))
        case .rideRental:
            return .bar(.otpRentalPurple)
        case .pickUpVehicle(let index):
            if row.state == .done, !isRiding(index) {
                return .thin
            }
            return .bar(.otpRentalPurple)
        case .walk, .getOff, .dropOffVehicle:
            return .thin
        }
    }

    private func isRiding(_ index: Int) -> Bool {
        if case .riding(let ridingIndex) = progress.phase { return ridingIndex == index }
        return false
    }

    // MARK: - Interactions

    private func handleTap(on row: RailRow) {
        // Tapping the current row means "back to now", never "focus" — focusing
        // where you already are would only summon the pill and stall auto-scroll.
        guard let legIndex = row.legIndex, row.state != .current else {
            focusedLegIndex = nil
            return
        }
        focusedLegIndex = focusedLegIndex == legIndex ? nil : legIndex
    }

    private var showsBackToNow: Bool {
        // A focused row always earns the pill — even pre-trip, when there is
        // no green pip yet, it's the way back out of an inspected leg.
        if focusedLegIndex != nil { return true }
        guard progress.phase.legIndex != nil else { return false }
        return !isCurrentRowVisible
    }

    // MARK: - Chrome

    /// The pre-trip banner: "Leave in 4m" is the single most valuable thing a
    /// planner can say, and it's just the first leg's start time minus now.
    private var leaveBanner: some View {
        NowCard {
            VStack(alignment: .leading, spacing: 5) {
                Text(OTPLoc("rail.leave_in_fmt",
                            comment: "Countdown until the rider must leave",
                            Formatters.formatCountdown(progress.secondsUntilStart)))
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(theme.primaryColor)

                Text(RailText.leaveInstruction(progress))
                    .font(.title3.weight(.semibold))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func backToNowPill(action: @escaping () -> Void) -> some View {
        // Back-to-now names the current leg, so it doubles as a status line
        // for the state the rider left behind. Pre-trip there is no current
        // activity to name, so the pill stays plain.
        let label = progress.localizedActivityName.map { activity in
            OTPLoc("rail.back_to_now_fmt",
                   comment: "Button returning the rail to the rider's current step; argument names that step",
                   activity)
        } ?? OTPLoc("rail.back_to_now", comment: "Returns the panel to the rider's current step")

        return Button(action: action) {
            Label(label, systemImage: "arrow.up")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 17)
                .padding(.vertical, 11)
                .background(Color(.label).opacity(0.9), in: Capsule())
                .shadow(color: .black.opacity(0.28), radius: 9, y: 6)
        }
        .buttonStyle(.plain)
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
