//
//  RailRowContentViews.swift
//  OTPKit
//
//  Created by Claude on 7/28/26.
//

import SwiftUI

// The content column of each rail row kind. The views are state-aware: done
// rows collapse to one line, current boarding/riding rows expand into the
// tinted NowCard, and a focused boarding row shows its full detail inside the
// neutral dark FocusedCard outline.

// MARK: - Shared helpers

enum RailText {
    /// The rider-facing route name for a transit leg ("C Line", "2").
    static func routeName(_ leg: Leg) -> String {
        leg.riderFacingRouteName
    }

    /// The pre-trip instruction: "Start walking at 9:38 PM to catch the C Line"
    /// when the trip opens with a walk toward transit, otherwise plain
    /// "Leave at 9:38 PM".
    static func leaveInstruction(_ progress: TripProgress) -> String {
        let startTime = Formatters.formatDateToTime(progress.legs.first?.startTime ?? progress.itinerary.startTime)
        if let firstLeg = progress.legs.first, firstLeg.transitLeg != true,
           let firstTransit = progress.legs.first(where: { $0.transitLeg == true }) {
            return OTPLoc("rail.start_walking_fmt",
                          comment: "Pre-trip instruction: when to start walking and which route it catches",
                          startTime, routeName(firstTransit))
        }
        return OTPLoc("rail.leave_at_fmt", comment: "Pre-trip instruction: when to leave", startTime)
    }

    /// What to say while waiting to board: a live countdown when the data is
    /// real-time, the scheduled departure otherwise. That gate is a product
    /// rule, so it lives here once.
    static func boardingCountdown(for leg: Leg, now: Date) -> String {
        let seconds = leg.startTime.timeIntervalSince(now)
        if seconds > 0, leg.realTime == true {
            return OTPLoc("rail.arriving_in_fmt",
                          comment: "Countdown until the vehicle arrives at the rider's stop",
                          Formatters.formatCountdown(seconds))
        }
        return OTPLoc("rail.departs_at_fmt",
                      comment: "Scheduled departure time of the vehicle",
                      Formatters.formatDateToTime(leg.startTime))
    }

    /// "12 stops" / "1 stop".
    static func stops(_ count: Int) -> String {
        count == 1
            ? OTPLoc("rail.stop_one", comment: "A ride of exactly one stop")
            : OTPLoc("rail.stops_fmt", comment: "Number of stops on a transit ride", count)
    }

    /// "4 stops to go" / "1 stop to go".
    static func stopsToGo(_ count: Int) -> String {
        count == 1
            ? OTPLoc("rail.one_stop_to_go", comment: "One stop until the rider gets off")
            : OTPLoc("rail.stops_to_go_fmt", comment: "Stops until the rider gets off", count)
    }

    /// Wait description after a leg: "Wait 6m for Route 2", using the same-stop
    /// variant when no street crossing is needed.
    static func waitDescription(progress: TripProgress, afterLegAt index: Int) -> String? {
        guard let wait = progress.waitAfterLeg(at: index),
              index + 1 < progress.legs.count,
              progress.legs[index + 1].transitLeg == true else {
            return nil
        }

        let nextRoute = routeName(progress.legs[index + 1])
        let waitString = Formatters.formatTimeDuration(Int(wait))
        if progress.isSameStopTransfer(fromLegAt: index) {
            return OTPLoc("rail.wait_same_stop_fmt",
                          comment: "Wait duration; the next route leaves from the same stop",
                          waitString, nextRoute)
        }
        return OTPLoc("rail.wait_for_fmt", comment: "Wait duration for the next route", waitString, nextRoute)
    }
}

// MARK: - Walk rows

/// "Walk 0.2 mi to Fauntleroy Way SW & SW Myrtle St" — with turn-by-turn
/// sub-steps expanded only when this is the current or focused row.
struct WalkRowContent: View {
    let leg: Leg
    let state: RailRow.State
    let isExpanded: Bool
    @Environment(\.otpTheme) private var theme

    var body: some View {
        if state == .done {
            Text(OTPLoc("rail.walked_done_fmt",
                        comment: "Collapsed row for a finished walking leg",
                        Formatters.formatDistance(Int(leg.distance))))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(OTPLoc("rail.walk_fmt",
                            comment: "Walking instruction: distance, then destination",
                            Formatters.formatDistance(Int(leg.distance)), leg.to.name))
                    .font(.body.weight(.semibold))

                Text(OTPLoc("rail.about_duration_fmt",
                            comment: "Approximate duration of a walking leg",
                            Formatters.formatTimeDuration(leg.duration)))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if isExpanded, let steps = leg.steps, !steps.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                            Text(step.localizedInstruction)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(theme.primaryColor.opacity(0.3))
                            .frame(width: 2)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

}

// MARK: - Board rows

/// Boarding point of a transit leg: badge + "Board", expanding into the
/// countdown now-card while the rider waits at the stop.
struct BoardRowContent: View {
    let progress: TripProgress
    let legIndex: Int
    let state: RailRow.State
    let isFocused: Bool

    private var leg: Leg { progress.legs[legIndex] }

    var body: some View {
        switch state {
        case .done:
            Text(OTPLoc("rail.boarded_done_fmt",
                        comment: "Collapsed row for a vehicle the rider already boarded",
                        RailText.routeName(leg)))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .current:
            NowCard { waitingDetail }
        case .upcoming:
            if isFocused {
                FocusedCard { focusedDetail }
            } else {
                summary
            }
        }
    }

    /// Two-line summary for an upcoming boarding.
    private var summary: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                RouteBadge(leg: leg)
                Text(OTPLoc("rail.board", comment: "Instruction to board a transit vehicle"))
                    .font(.body.weight(.semibold))
            }
            subtitleLine
        }
    }

    /// The countdown card shown while waiting at the stop. This is where
    /// real-time earns its keep: "Arriving in 1m" instead of "Scheduled at 9:42 PM".
    private var waitingDetail: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 9) {
                RouteBadge(leg: leg)
                Text(RailText.boardingCountdown(for: leg, now: progress.now))
                    .font(.title3.weight(.semibold))
            }

            stopReferenceLine
            rideSummaryLine
        }
    }

    /// Everything OTP knows about the boarding, shown when the rider taps the
    /// row — replaces the old separate detail screen entirely.
    private var focusedDetail: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 9) {
                RouteBadge(leg: leg)
                Text(OTPLoc("rail.board", comment: "Instruction to board a transit vehicle"))
                    .font(.title3.weight(.semibold))
            }

            stopReferenceLine
            rideSummaryLine

            if legIndex > 0, progress.isSameStopTransfer(fromLegAt: legIndex - 1) {
                Label {
                    Text(OTPLoc("rail.same_stop_note",
                                comment: "The transfer departs from the stop where the rider arrived"))
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond")
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 9))
                .padding(.top, 5)
            }
        }
    }

    /// Stop name and code in reference position: at the stop, the code is how
    /// you confirm you're at the right pole.
    @ViewBuilder
    private var stopReferenceLine: some View {
        let name = OTPLoc("rail.at_stop_fmt", comment: "The stop the rider boards at", leg.from.name)
        if let code = leg.from.stopCode {
            Text("\(name) · \(OTPLoc("rail.stop_code_fmt", comment: "Agency stop code", code))")
                .font(.subheadline)
        } else {
            Text(name)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    private var rideSummaryLine: some View {
        if let headsign = leg.headsign, let total = progress.totalStops(onLegAt: legIndex) {
            let ride = OTPLoc("rail.ride_stops_duration_fmt",
                              comment: "Stop count and duration of the ride",
                              RailText.stops(total),
                              Formatters.formatTimeDuration(leg.duration))
            Text(OTPLoc("rail.toward_stops_fmt",
                        comment: "Vehicle headsign, then ride summary", headsign, ride))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            subtitleLine
        }
    }

    @ViewBuilder
    private var subtitleLine: some View {
        if let headsign = leg.headsign {
            let stops = progress.totalStops(onLegAt: legIndex).map(RailText.stops) ??
                Formatters.formatTimeDuration(leg.duration)
            Text(OTPLoc("rail.toward_stops_fmt",
                        comment: "Vehicle headsign, then ride summary", headsign, stops))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Ride row

/// The synthetic row present only while aboard: "4 stops to go" with the leg's
/// final approach nested inside the now-card, so trip context above and below
/// never disappears.
struct RideRowContent: View {
    let progress: TripProgress
    let legIndex: Int

    private var leg: Leg { progress.legs[legIndex] }

    var body: some View {
        NowCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 9) {
                    RouteBadge(leg: leg)
                    if let remaining = progress.stopsRemaining(onLegAt: legIndex) {
                        Text(RailText.stopsToGo(remaining))
                            .font(.title3.weight(.semibold))
                    }
                }

                Text(OTPLoc("rail.get_off_at_fmt",
                            comment: "The stop where the rider gets off", leg.to.name))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                stopLadder
            }
        }
    }

    /// The leg's last few stops before alighting (a fixed preview, not a live
    /// countdown — per-stop times aren't decoded yet), with the final
    /// intermediate stop emphasized as the "get ready" cue.
    @ViewBuilder
    private var stopLadder: some View {
        if let stops = leg.intermediateStops, !stops.isEmpty {
            let upcoming = Array(stops.suffix(3))
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(upcoming.enumerated()), id: \.offset) { index, stop in
                    Text(stop.name)
                        .font(.subheadline)
                        .foregroundStyle(index == upcoming.count - 1 ? Color.primary : Color.secondary)
                }
            }
            .padding(.leading, 12)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill((leg.routeUIColor ?? Color(.systemGray3)).opacity(0.4))
                    .frame(width: 2)
            }
            .padding(.top, 5)
        }
    }
}

// MARK: - Get off rows

/// "Get off at 3rd Ave & Virginia St", with the wait for the next vehicle as
/// its subtitle.
struct GetOffRowContent: View {
    let progress: TripProgress
    let legIndex: Int
    let state: RailRow.State

    private var leg: Leg { progress.legs[legIndex] }

    var body: some View {
        if state == .done {
            Text(OTPLoc("rail.get_off_at_fmt",
                        comment: "The stop where the rider gets off", leg.to.name))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(OTPLoc("rail.get_off_at_fmt",
                            comment: "The stop where the rider gets off", leg.to.name))
                    .font(.body.weight(.semibold))

                if let wait = RailText.waitDescription(progress: progress, afterLegAt: legIndex) {
                    Text(wait)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Arrive row

/// The final destination row: a solid dark pip and one word.
struct ArriveRowContent: View {
    var body: some View {
        Text(OTPLoc("rail.arrive", comment: "Final row of the trip: arrival at the destination"))
            .font(.body.weight(.semibold))
    }
}
