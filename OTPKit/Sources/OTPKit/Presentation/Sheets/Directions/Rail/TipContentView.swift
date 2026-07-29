//
//  TipContentView.swift
//  OTPKit
//
//  Created by Claude on 7/28/26.
//

import SwiftUI

/// The 160pt tip detent: one instruction, a live countdown, and trip progress.
/// The map above does the wayfinding; this stays glanceable at arm's length.
///
/// The ‹ › stepper keeps the one thing riders already knew from the old pager —
/// stepping leg by leg — but as a real hit target. The progress bar doubles as
/// the stepper's track: elapsed fill shows where `currentLeg` is, the outlined
/// segment is `focusedLeg`, so the two cursors are never ambiguous.
struct TipContentView: View {
    let trip: Trip
    let progress: TripProgress
    @Binding var focusedLegIndex: Int?

    @Environment(\.otpTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes the detent grows (see TipDetent), and anything
        // still taller scrolls rather than clips.
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView { tipBody }
        } else {
            tipBody
        }
    }

    private var tipBody: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                stepperButton(systemImage: "chevron.left", enabled: canStepBack) {
                    step(by: -1)
                }

                instructionContent
                    .frame(maxWidth: .infinity, alignment: .leading)

                stepperButton(systemImage: "chevron.right", enabled: canStepForward) {
                    step(by: 1)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            Spacer(minLength: 8)

            VStack(spacing: 7) {
                TripProgressBarView(progress: progress, focusedLegIndex: focusedLegIndex)

                HStack {
                    Text(footerLeadingText)
                        .foregroundStyle(.secondary)
                    Spacer()
                    footerTrailing
                }
                .font(.footnote)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Instruction

    @ViewBuilder
    private var instructionContent: some View {
        if let focusedLegIndex, focusedLegIndex < progress.legs.count {
            legPreview(progress.legs[focusedLegIndex])
        } else {
            liveInstruction
        }
    }

    /// What to do right now, driven by the trip phase.
    @ViewBuilder
    private var liveInstruction: some View {
        switch progress.phase {
        case .notStarted:
            HStack(alignment: .top, spacing: 12) {
                walkIcon
                title(RailText.leaveInstruction(progress),
                      subtitle: trip.destination.title)
                trailingCountdown(
                    Formatters.formatCountdown(progress.secondsUntilStart),
                    color: theme.primaryColor
                )
            }

        case .walking(let index):
            let leg = progress.legs[index]
            HStack(alignment: .top, spacing: 12) {
                walkIcon
                title(OTPLoc("rail.walk_fmt",
                             comment: "Walking instruction: distance, then destination",
                             Formatters.formatDistance(Int(leg.distance)), leg.riderFacingToName),
                      subtitle: progress.currentStep(onLegAt: index)?.localizedInstruction)
                trailingCountdown(
                    Formatters.formatCountdown(leg.endTime.timeIntervalSince(progress.now)),
                    color: theme.primaryColor
                )
            }

        case .waiting(let index):
            let leg = progress.legs[index]
            if leg.isRentalRide {
                HStack(alignment: .top, spacing: 12) {
                    bikeIcon
                    title(OTPLoc("rail.pick_up_bike", comment: "Instruction to pick up the rental bike"),
                          subtitle: RailText.rentalPlaceName(leg.from.name))
                    trailingTime(leg.startTime, status: nil)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    RouteBadge(leg: leg)
                    title(RailText.boardingCountdown(for: leg, now: progress.now),
                          subtitle: OTPLoc("rail.at_stop_fmt",
                                           comment: "The stop the rider boards at", leg.from.name))
                    trailingTime(leg.startTime, status: leg.departureStatus)
                }
            }

        case .riding(let index):
            let leg = progress.legs[index]
            if leg.isRentalRide {
                HStack(alignment: .top, spacing: 12) {
                    bikeIcon
                    title(OTPLoc("rail.ride_bike_to_fmt",
                                 comment: "Riding instruction: where the rental ride ends",
                                 leg.riderFacingToName),
                          subtitle: OTPLoc("rail.drop_off_bike",
                                           comment: "Instruction to drop off the rental bike"))
                    trailingTime(leg.endTime, status: nil)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    RouteBadge(leg: leg)
                    title(progress.stopsRemaining(onLegAt: index).map(RailText.stopsToGo) ?? RailText.routeName(leg),
                          subtitle: OTPLoc("rail.get_off_at_fmt",
                                           comment: "The stop where the rider gets off", leg.to.name))
                    trailingTime(leg.endTime, status: leg.arrivalStatus)
                }
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
    private func legPreview(_ leg: Leg) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if leg.transitLeg == true {
                RouteBadge(leg: leg)
                title(RailText.routeName(leg),
                      subtitle: leg.headsign.map {
                          OTPLoc("rail.toward_fmt", comment: "Vehicle headsign", $0)
                      } ?? leg.to.name)
            } else if leg.isRentalRide {
                bikeIcon
                title(OTPLoc("rail.ride_bike_to_fmt",
                             comment: "Riding instruction: where the rental ride ends",
                             leg.riderFacingToName),
                      subtitle: OTPLoc("rail.about_duration_fmt",
                                       comment: "Approximate duration of a walking leg",
                                       Formatters.formatTimeDuration(leg.duration)))
            } else {
                walkIcon
                title(OTPLoc("rail.walk_fmt",
                             comment: "Walking instruction: distance, then destination",
                             Formatters.formatDistance(Int(leg.distance)), leg.riderFacingToName),
                      subtitle: OTPLoc("rail.about_duration_fmt",
                                       comment: "Approximate duration of a walking leg",
                                       Formatters.formatTimeDuration(leg.duration)))
            }
            trailingTime(leg.startTime, status: nil)
        }
    }

    // MARK: - Pieces

    private var walkIcon: some View {
        modeIcon("figure.walk", background: Color(.label))
    }

    private var bikeIcon: some View {
        modeIcon("bicycle", background: .otpRentalPurple)
    }

    private func modeIcon(_ systemName: String, background: Color) -> some View {
        Image(systemName: systemName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(background, in: RoundedRectangle(cornerRadius: 9))
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

    private var currentLegIndex: Int? {
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
    private var canStepBack: Bool {
        guard let currentLegIndex else { return false }
        return (focusedLegIndex ?? currentLegIndex) > currentLegIndex
    }

    private var canStepForward: Bool {
        guard let currentLegIndex else { return false }
        return (focusedLegIndex ?? currentLegIndex) < progress.legs.count - 1
    }

    private func step(by delta: Int) {
        guard let currentLegIndex else { return }
        let next = (focusedLegIndex ?? currentLegIndex) + delta
        guard next >= currentLegIndex, next < progress.legs.count else { return }
        focusedLegIndex = next == currentLegIndex ? nil : next
    }
}

// MARK: - Footer & Copy

private extension TipContentView {
    var footerLeadingText: String {
        let current = currentLegIndex ?? 0
        let stepNumber = (focusedLegIndex ?? current) + 1

        if focusedLegIndex != nil {
            return OTPLoc("rail.step_of_previewing_fmt",
                          comment: "Stepper position while previewing a future leg",
                          stepNumber, progress.legs.count)
        }

        // Name the next boarding so the footer answers "what's next."
        if let nextTransitIndex = progress.nextBoardingIndex {
            let nextLeg = progress.legs[nextTransitIndex]
            return OTPLoc("rail.next_leg_fmt",
                          comment: "Current activity, then the next route and its time",
                          currentActivity,
                          RailText.routeName(nextLeg),
                          Formatters.formatDateToTime(nextLeg.startTime))
        }
        return OTPLoc("rail.last_step", comment: "The rider is on the trip's final step")
    }

    /// The footer's leading word: the live activity, or the leave-in countdown
    /// before the trip starts — pre-trip, nobody is "Walking" yet.
    var currentActivity: String {
        if progress.phase == .notStarted {
            return OTPLoc("rail.leave_in_fmt",
                          comment: "Countdown until the rider must leave",
                          Formatters.formatCountdown(progress.secondsUntilStart))
        }
        return progress.localizedActivityName
            ?? OTPLoc("rail.now_walking", comment: "The rider is currently walking")
    }

    @ViewBuilder
    var footerTrailing: some View {
        if focusedLegIndex != nil {
            Button {
                focusedLegIndex = nil
            } label: {
                Text(OTPLoc("rail.back_to_now", comment: "Returns the panel to the rider's current step"))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(theme.primaryColor)
            }
        } else {
            Text(arrivalFooterText)
                .foregroundStyle(.secondary)
        }
    }

    /// "Arrive 10:29 PM" with the time bolded in place, so locales that put
    /// the placeholder first (e.g. zh-Hans "%@ 到达") keep their word order.
    var arrivalFooterText: AttributedString {
        let time = Formatters.formatDateToTime(progress.itinerary.endTime)
        var text = AttributedString(
            OTPLoc("rail.arrive_time_fmt", comment: "Trailing arrival time", time)
        )
        if let range = text.range(of: time) {
            text[range].font = .footnote.bold()
        }
        return text
    }

}
