//
//  TripHeaderView.swift
//  OTPKit
//
//  Created by Claude on 7/28/26.
//

import SwiftUI

/// The destination header pinned above the rail: name + arrival + duration.
/// It never scrolls, because it's the only thing a rider checks more than once —
/// it is always the answer to "am I going to make it."
struct TripHeaderView: View {
    let trip: Trip
    let progress: TripProgress

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(OTPLoc("rail.arrive_at_fmt",
                            comment: "Header label naming the destination", trip.destination.title))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                arrivalTime
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(remainingText)
                Text(transfersText)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    /// The big arrival number. When the last transit leg is running late the
    /// time turns violet and the original schedule stays visible, struck
    /// through — riders need to know how far off plan they are.
    @ViewBuilder
    private var arrivalTime: some View {
        let delay = arrivalDelaySeconds
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(Formatters.formatDateToTime(progress.itinerary.endTime))
                .font(.title.bold())
                .foregroundStyle(delay > 60 ? RealTimeStatus.late(minutes: 0).color : Color.primary)

            if delay > 60 {
                Text(Formatters.formatDateToTime(progress.itinerary.endTime.addingTimeInterval(-Double(delay))))
                    .font(.body)
                    .strikethrough()
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Arrival delay in seconds carried by the trip's final transit leg.
    private var arrivalDelaySeconds: Int {
        progress.legs.last(where: { $0.transitLeg == true })?.arrivalDelay ?? 0
    }

    private var remainingText: String {
        switch progress.phase {
        case .notStarted:
            return Formatters.formatTimeDuration(progress.itinerary.duration)
        case .arrived:
            return OTPLoc("rail.arrived", comment: "The rider has reached the destination")
        default:
            return OTPLoc("rail.time_left_fmt",
                          comment: "Time remaining until arrival",
                          Formatters.formatTimeDuration(Int(progress.secondsRemaining)))
        }
    }

    private var transfersText: String {
        let transfers = progress.itinerary.transfers
        return transfers == 1
            ? OTPLoc("rail.transfer_one", comment: "Trip has one transfer")
            : OTPLoc("rail.transfers_fmt", comment: "Number of transfers in the trip", transfers)
    }
}
