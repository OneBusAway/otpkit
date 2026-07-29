//
//  TipContentView.swift
//  OTPKit
//
//  Created by Claude on 7/28/26.
//

import SwiftUI

/// The 150pt tip detent: one instruction, a live countdown, and trip progress.
/// The map above does the wayfinding; this stays glanceable at arm's length.
///
/// The ‹ › stepper keeps the one thing riders already knew from the old pager —
/// stepping leg by leg — but as a real hit target. The progress bar doubles as
/// the stepper's track: green fill is `currentLeg`, the outlined segment is
/// `focusedLeg`, so the two cursors are never ambiguous.
struct TipContentView: View {
    let trip: Trip
    let now: Date
    @Binding var focusedLegIndex: Int?
    let onFocusLeg: (Leg?) -> Void

    @Environment(\.otpTheme) private var theme

    private var progress: TripProgress {
        TripProgress(itinerary: trip.itinerary, now: now)
    }

    var body: some View {
        let progress = self.progress

        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                stepperButton(systemImage: "chevron.left", enabled: canStepBack(progress)) {
                    step(by: -1, progress: progress)
                }

                instructionContent(progress)
                    .frame(maxWidth: .infinity, alignment: .leading)

                stepperButton(systemImage: "chevron.right", enabled: canStepForward(progress)) {
                    step(by: 1, progress: progress)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            Spacer(minLength: 8)

            VStack(spacing: 7) {
                TripProgressBarView(progress: progress, focusedLegIndex: focusedLegIndex)

                HStack {
                    Text(footerLeadingText(progress))
                        .foregroundStyle(.secondary)
                    Spacer()
                    footerTrailing(progress)
                }
                .font(.footnote)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Instruction

    @ViewBuilder
    private func instructionContent(_ progress: TripProgress) -> some View {
        let displayIndex = focusedLegIndex ?? currentLegIndex(progress)

        if focusedLegIndex == nil {
            liveInstruction(progress)
        } else if let displayIndex, displayIndex < progress.legs.count {
            legPreview(progress.legs[displayIndex], progress: progress, index: displayIndex)
        }
    }

    /// What to do right now, driven by the trip phase.
    @ViewBuilder
    private func liveInstruction(_ progress: TripProgress) -> some View {
        switch progress.phase {
        case .notStarted:
            HStack(alignment: .top, spacing: 12) {
                walkIcon
                title(leaveInstruction(progress),
                      subtitle: trip.destination.title)
                trailingCountdown(
                    Formatters.formatTimeDuration(max(60, Int(progress.secondsUntilStart))),
                    color: theme.primaryColor
                )
            }

        case .walking(let index):
            let leg = progress.legs[index]
            HStack(alignment: .top, spacing: 12) {
                walkIcon
                title(OTPLoc("rail.walk_fmt",
                             comment: "Walking instruction: distance, then destination",
                             Formatters.formatDistance(Int(leg.distance)), leg.to.name),
                      subtitle: currentStepText(leg))
                trailingCountdown(
                    Formatters.formatTimeDuration(max(60, Int(leg.endTime.timeIntervalSince(now)))),
                    color: theme.primaryColor
                )
            }

        case .waiting(let index):
            let leg = progress.legs[index]
            HStack(alignment: .top, spacing: 12) {
                RouteBadge(leg: leg)
                title(waitingTitle(leg),
                      subtitle: OTPLoc("rail.at_stop_fmt",
                                       comment: "The stop the rider boards at", leg.from.name))
                trailingTime(leg.startTime, status: leg.departureStatus)
            }

        case .riding(let index):
            let leg = progress.legs[index]
            HStack(alignment: .top, spacing: 12) {
                RouteBadge(leg: leg)
                title(progress.stopsRemaining(onLegAt: index).map(RailText.stopsToGo) ?? RailText.routeName(leg),
                      subtitle: OTPLoc("rail.get_off_at_fmt",
                                       comment: "The stop where the rider gets off", leg.to.name))
                trailingTime(leg.endTime, status: leg.arrivalStatus)
            }

        case .arrived:
            HStack(alignment: .top, spacing: 12) {
                walkIcon
                title(OTPLoc("rail.arrived", comment: "The rider has reached the destination"),
                      subtitle: trip.destination.title)
            }
        }
    }

    /// The focused (previewed) leg, when the stepper has moved off "now".
    @ViewBuilder
    private func legPreview(_ leg: Leg, progress: TripProgress, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if leg.transitLeg == true {
                RouteBadge(leg: leg)
                title(RailText.routeName(leg),
                      subtitle: leg.headsign.map {
                          OTPLoc("rail.toward_fmt", comment: "Vehicle headsign", $0)
                      } ?? leg.to.name)
            } else {
                walkIcon
                title(OTPLoc("rail.walk_fmt",
                             comment: "Walking instruction: distance, then destination",
                             Formatters.formatDistance(Int(leg.distance)), leg.to.name),
                      subtitle: OTPLoc("rail.about_duration_fmt",
                                       comment: "Approximate duration of a walking leg",
                                       Formatters.formatTimeDuration(leg.duration)))
            }
            trailingTime(leg.startTime, status: nil)
        }
    }

    // MARK: - Pieces

    private var walkIcon: some View {
        Image(systemName: "figure.walk")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(Color(.label), in: RoundedRectangle(cornerRadius: 9))
            .accessibilityHidden(true)
    }

    private func title(_ text: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(text)
                .font(.title3.weight(.semibold))
                .lineLimit(2)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func trailingCountdown(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title3.weight(.semibold))
            .foregroundStyle(color)
            .fixedSize()
    }

    private func trailingTime(_ time: Date, status: RealTimeStatus?) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(Formatters.formatDateToTime(time))
                .font(.title3.weight(.semibold))
            if let status {
                Text(status.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(status.color)
            }
        }
        .fixedSize()
    }

    private func stepperButton(systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(width: 30, height: 30)
                .background(
                    enabled ? theme.primaryColor.opacity(0.12) : Color(.systemGray5),
                    in: Circle()
                )
                .foregroundStyle(enabled ? theme.primaryColor : Color(.systemGray3))
        }
        .frame(width: 44, height: 44)
        .disabled(!enabled)
        .padding(.top, 2)
    }

    // MARK: - Stepper Logic

    private func currentLegIndex(_ progress: TripProgress) -> Int? {
        switch progress.phase {
        case .notStarted:
            return progress.legs.isEmpty ? nil : 0
        case .arrived:
            return progress.legs.isEmpty ? nil : progress.legs.count - 1
        default:
            return progress.phase.legIndex
        }
    }

    /// ‹ is dimmed at the current leg rather than wrapping — a rider mid-trip
    /// has no reason to step backward into completed legs.
    private func canStepBack(_ progress: TripProgress) -> Bool {
        guard let current = currentLegIndex(progress) else { return false }
        return (focusedLegIndex ?? current) > current
    }

    private func canStepForward(_ progress: TripProgress) -> Bool {
        guard let current = currentLegIndex(progress) else { return false }
        return (focusedLegIndex ?? current) < progress.legs.count - 1
    }

    private func step(by delta: Int, progress: TripProgress) {
        guard let current = currentLegIndex(progress) else { return }
        let next = (focusedLegIndex ?? current) + delta
        guard next >= current, next < progress.legs.count else { return }

        if next == current {
            focusedLegIndex = nil
            onFocusLeg(nil)
        } else {
            focusedLegIndex = next
            onFocusLeg(progress.legs[next])
        }
    }

}

// MARK: - Footer & Copy

private extension TipContentView {
    func footerLeadingText(_ progress: TripProgress) -> String {
        let current = currentLegIndex(progress) ?? 0
        let stepNumber = (focusedLegIndex ?? current) + 1

        if focusedLegIndex != nil {
            return OTPLoc("rail.step_of_previewing_fmt",
                          comment: "Stepper position while previewing a future leg",
                          stepNumber, progress.legs.count)
        }

        // Name the next boarding so the footer answers "what's next." Before
        // the rider is aboard, the current leg's own boarding still counts.
        let isAboardCurrent = {
            if case .riding = progress.phase { return true }
            return false
        }()
        let nextTransitIndex = progress.legs.indices.first {
            ($0 > current || ($0 == current && !isAboardCurrent)) && progress.legs[$0].transitLeg == true
        }
        if let nextTransitIndex {
            let nextLeg = progress.legs[nextTransitIndex]
            return OTPLoc("rail.next_leg_fmt",
                          comment: "Current activity, then the next route and its time",
                          currentActivityName(progress),
                          RailText.routeName(nextLeg),
                          Formatters.formatDateToTime(nextLeg.startTime))
        }
        return OTPLoc("rail.last_step", comment: "The rider is on the trip's final step")
    }

    @ViewBuilder
    private func footerTrailing(_ progress: TripProgress) -> some View {
        if focusedLegIndex != nil {
            Button {
                focusedLegIndex = nil
                onFocusLeg(nil)
            } label: {
                Text(OTPLoc("rail.back_to_now", comment: "Returns the panel to the rider's current step"))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(theme.primaryColor)
            }
        } else {
            (Text(OTPLoc("rail.arrive_time_fmt", comment: "Trailing arrival time", ""))
                + Text(Formatters.formatDateToTime(trip.itinerary.endTime)).bold())
                .foregroundStyle(.secondary)
        }
    }

    private func currentActivityName(_ progress: TripProgress) -> String {
        switch progress.phase {
        case .waiting(let index):
            return OTPLoc("rail.now_waiting_fmt",
                          comment: "The rider is waiting for this route",
                          RailText.routeName(progress.legs[index]))
        case .riding(let index):
            return OTPLoc("rail.now_riding_fmt",
                          comment: "The rider is aboard this route",
                          RailText.routeName(progress.legs[index]))
        default:
            return OTPLoc("rail.now_walking", comment: "The rider is currently walking")
        }
    }

    private func waitingTitle(_ leg: Leg) -> String {
        let seconds = leg.startTime.timeIntervalSince(now)
        if seconds > 0, leg.realTime == true {
            return OTPLoc("rail.arriving_in_fmt",
                          comment: "Countdown until the vehicle arrives at the rider's stop",
                          Formatters.formatTimeDuration(max(60, Int(seconds))))
        }
        return OTPLoc("rail.departs_at_fmt",
                      comment: "Scheduled departure time of the vehicle",
                      Formatters.formatDateToTime(leg.startTime))
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

    private func currentStepText(_ leg: Leg) -> String? {
        guard let steps = leg.steps, !steps.isEmpty else { return nil }
        let duration = leg.endTime.timeIntervalSince(leg.startTime)
        guard duration > 0 else { return nil }

        let fraction = min(0.999, max(0, now.timeIntervalSince(leg.startTime) / duration))
        let step = steps[Int(fraction * Double(steps.count))]
        let distance = Formatters.formatDistance(Int(step.distance))
        if let direction = step.directionDisplayName {
            return "\(direction) \(step.streetName) · \(distance)"
        }
        return "\(step.streetName) · \(distance)"
    }
}
