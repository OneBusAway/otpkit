/*
 * Copyright (C) Open Transit Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/// Where the rider is in an itinerary right now.
///
/// This is the `currentLeg` cursor of the in-trip panel's two-cursor model: it
/// advances only with the clock (and, later, location) — never from a tap.
public enum TripPhase: Equatable {
    /// The trip hasn't begun yet; the first leg starts in the future.
    case notStarted

    /// The rider is on a non-transit (walking) leg.
    case walking(legIndex: Int)

    /// The rider has finished the previous leg and is waiting to board transit.
    case waiting(boardingLegIndex: Int)

    /// The rider is aboard a transit leg or riding a rental vehicle.
    case riding(legIndex: Int)

    /// The itinerary's end time has passed.
    case arrived

    /// The index of the leg the rider is currently on (or about to board), if any.
    public var legIndex: Int? {
        switch self {
        case .notStarted, .arrived:
            return nil
        case .walking(let index), .riding(let index):
            return index
        case .waiting(let index):
            return index
        }
    }
}

/// A single row of the in-trip progress rail.
///
/// The rail flattens an itinerary's legs into rider moments: one row per walking
/// leg, two rows per transit leg (board and get off), plus a synthetic riding row
/// while aboard, and a final arrival row.
public struct RailRow: Identifiable, Equatable {
    public enum Kind: Equatable {
        /// Walk this leg.
        case walk(legIndex: Int)
        /// Board the transit vehicle for this leg.
        case board(legIndex: Int)
        /// Currently riding this leg. Present only while `TripPhase.riding` this leg.
        case ride(legIndex: Int)
        /// Alight from this leg.
        case getOff(legIndex: Int)
        /// Pick up the rental vehicle that starts this rental ride leg.
        case pickUpVehicle(legIndex: Int)
        /// Currently riding this rental leg. Present only while `TripPhase.riding` it.
        case rideRental(legIndex: Int)
        /// Drop off the rental vehicle at the end of this rental ride leg.
        case dropOffVehicle(legIndex: Int)
        /// The final destination.
        case arrive
    }

    public enum State: Equatable {
        /// Behind the rider. Collapses to one line at reduced opacity.
        case done
        /// Where the rider is: exactly one row while the trip is underway,
        /// none before it starts.
        case current
        /// Still ahead.
        case upcoming
    }

    public let id: String
    public let kind: Kind
    public let state: State

    /// The time shown in the row's gutter.
    public let time: Date

    /// Real-time status shown beneath the gutter time, for boarding rows.
    public let status: RealTimeStatus?

    /// The index of the leg this row belongs to, if any.
    public var legIndex: Int? {
        switch kind {
        case .walk(let index), .board(let index), .ride(let index), .getOff(let index),
             .pickUpVehicle(let index), .rideRental(let index), .dropOffVehicle(let index):
            return index
        case .arrive:
            return nil
        }
    }
}

/// Pure computation of in-trip progress from an itinerary and the current time.
///
/// Views feed `Date()` (via `TimelineView`) in; everything out is derived, which
/// keeps the whole in-trip state machine unit-testable without a clock.
public struct TripProgress {
    public let itinerary: Itinerary
    public let now: Date

    /// Legs after merging same-route continuations and dropping sub-minute walks.
    public let legs: [Leg]

    public init(itinerary: Itinerary, now: Date) {
        self.itinerary = itinerary
        self.now = now
        self.legs = itinerary.relevantLegs
    }

    // MARK: - Current Leg Cursor

    /// Where the rider is right now, judged by the clock against leg times.
    public var phase: TripPhase {
        guard let firstLeg = legs.first else { return .arrived }

        if now < firstLeg.startTime {
            return .notStarted
        }

        for (index, leg) in legs.enumerated() {
            // Inside the leg's own time window. Rental rides count as riding even
            // though they are not transit legs.
            if now >= leg.startTime && now < leg.endTime {
                let isAboard = leg.transitLeg == true || leg.isRentalRide
                return isAboard ? .riding(legIndex: index) : .walking(legIndex: index)
            }

            // In the gap between this leg and the next: waiting if the next leg is
            // transit (the rider is at the stop) or a rental pickup (the rider is
            // walking up to the vehicle — sub-minute walks get merged away, leaving
            // a real gap). Otherwise the gap is part of the upcoming walk.
            if now < leg.startTime {
                let isBoardable = leg.transitLeg == true || leg.isRentalRide
                return isBoardable ? .waiting(boardingLegIndex: index) : .walking(legIndex: index)
            }
        }

        return .arrived
    }

    // MARK: - Rail Rows

    /// The full rail, with each row's state resolved against the current phase.
    public var rows: [RailRow] {
        var rows: [RailRow] = []
        let phase = self.phase

        for (index, leg) in legs.enumerated() {
            if leg.transitLeg == true {
                rows.append(boardRow(for: leg, at: index, phase: phase))
                if isRiding(index, phase: phase) {
                    rows.append(currentRideRow(id: "ride-\(index)", kind: .ride(legIndex: index)))
                }
                rows.append(legEndRow(id: "getoff-\(index)", kind: .getOff(legIndex: index), for: leg))
            } else if leg.isRentalRide {
                // Rental legs get pickup → ride → dropoff semantics, mirroring the
                // transit board → ride → get off shape so the rail reads uniformly.
                rows.append(pickUpVehicleRow(for: leg, at: index, phase: phase))
                if isRiding(index, phase: phase) {
                    rows.append(currentRideRow(id: "riderental-\(index)", kind: .rideRental(legIndex: index)))
                }
                rows.append(legEndRow(id: "dropoff-\(index)", kind: .dropOffVehicle(legIndex: index), for: leg))
            } else {
                rows.append(walkRow(for: leg, at: index, phase: phase))
            }
        }

        rows.append(
            RailRow(
                id: "arrive",
                kind: .arrive,
                state: phase == .arrived ? .current : .upcoming,
                time: itinerary.endTime,
                status: nil
            )
        )

        return rows
    }

    private func walkRow(for leg: Leg, at index: Int, phase: TripPhase) -> RailRow {
        let state: RailRow.State
        switch phase {
        case .walking(let walkingIndex) where walkingIndex == index:
            state = .current
        default:
            state = now >= leg.endTime ? .done : .upcoming
        }

        return RailRow(id: "walk-\(index)", kind: .walk(legIndex: index), state: state, time: leg.startTime, status: nil)
    }

    private func boardRow(for leg: Leg, at index: Int, phase: TripPhase) -> RailRow {
        let state: RailRow.State
        if case .waiting(let boardingIndex) = phase, boardingIndex == index {
            state = .current
        } else {
            state = now >= leg.startTime ? .done : .upcoming
        }

        return RailRow(
            id: "board-\(index)",
            kind: .board(legIndex: index),
            state: state,
            time: leg.startTime,
            status: leg.departureStatus
        )
    }

    /// The pickup row goes current during a `.waiting` gap before the ride — the
    /// stretch where the rider is walking up to the parked vehicle. During the ride
    /// itself the current row is the synthetic `rideRental` row.
    private func pickUpVehicleRow(for leg: Leg, at index: Int, phase: TripPhase) -> RailRow {
        let state: RailRow.State
        if case .waiting(let boardingIndex) = phase, boardingIndex == index {
            state = .current
        } else {
            state = now >= leg.startTime ? .done : .upcoming
        }

        return RailRow(
            id: "pickup-\(index)",
            kind: .pickUpVehicle(legIndex: index),
            state: state,
            time: leg.startTime,
            status: nil
        )
    }

    /// The synthetic row present only while the rider is aboard this leg.
    private func currentRideRow(id: String, kind: RailRow.Kind) -> RailRow {
        RailRow(id: id, kind: kind, state: .current, time: now, status: nil)
    }

    /// A leg's final moment: get off transit, or drop off the rental vehicle.
    private func legEndRow(id: String, kind: RailRow.Kind, for leg: Leg) -> RailRow {
        RailRow(id: id, kind: kind, state: now >= leg.endTime ? .done : .upcoming, time: leg.endTime, status: nil)
    }

    private func isRiding(_ index: Int, phase: TripPhase) -> Bool {
        if case .riding(let ridingIndex) = phase { return ridingIndex == index }
        return false
    }

    /// The rider's current activity, localized ("Walking", "Waiting for the C Line",
    /// "Riding C Line"). Nil before the trip starts and after it ends — the one
    /// vocabulary shared by the Back-to-now pill, the tip footer, and the
    /// VoiceOver auto-advance announcement.
    public var localizedActivityName: String? {
        switch phase {
        case .walking:
            return OTPLoc("rail.now_walking", comment: "The rider is currently walking")
        case .waiting(let index):
            if legs[index].isRentalRide {
                return OTPLoc("rail.pick_up_bike", comment: "Instruction to pick up the rental bike")
            }
            return OTPLoc("rail.now_waiting_fmt",
                          comment: "The rider is waiting for this route",
                          legs[index].riderFacingRouteName)
        case .riding(let index):
            if legs[index].isRentalRide {
                return OTPLoc("rail.now_riding_rental", comment: "The rider is riding a rental bike")
            }
            return OTPLoc("rail.now_riding_fmt",
                          comment: "The rider is aboard this route",
                          legs[index].riderFacingRouteName)
        case .notStarted, .arrived:
            return nil
        }
    }

    /// Real-time status of the trip's final transit arrival — what the header's
    /// late treatment keys off.
    public var arrivalStatus: RealTimeStatus {
        legs.last(where: { $0.transitLeg == true })?.arrivalStatus ?? .scheduled
    }

    // MARK: - Rider Questions

    /// Seconds until the first leg starts. Positive only before the trip begins.
    public var secondsUntilStart: TimeInterval {
        guard let firstLeg = legs.first else { return 0 }
        return firstLeg.startTime.timeIntervalSince(now)
    }

    /// Seconds until the rider arrives, floored at zero.
    public var secondsRemaining: TimeInterval {
        max(0, itinerary.endTime.timeIntervalSince(now))
    }

    /// Seconds of waiting between leg `index` ending and the next leg starting.
    /// Gaps of a minute or less aren't worth telling the rider about, so they
    /// return nil.
    public func waitAfterLeg(at index: Int) -> TimeInterval? {
        guard index >= 0, index + 1 < legs.count else { return nil }
        let gap = legs[index + 1].startTime.timeIntervalSince(legs[index].endTime)
        return gap > 60 ? gap : nil
    }

    /// The next transit boarding worth naming to the rider. While walking (or
    /// before the trip starts) the current leg's own boarding still counts;
    /// riding or already waiting at the stop, only later boardings do —
    /// "Waiting for the C Line · C Line at 9:42" would say the same thing
    /// twice. Nil when no boarding remains ahead.
    public var nextBoardingIndex: Int? {
        let current: Int
        switch phase {
        case .notStarted:
            current = 0
        case .arrived:
            current = legs.count - 1
        default:
            current = phase.legIndex ?? 0
        }

        let includesCurrentBoarding: Bool
        switch phase {
        case .riding, .waiting:
            includesCurrentBoarding = false
        default:
            includesCurrentBoarding = true
        }

        return legs.indices.first {
            ($0 > current || ($0 == current && includesCurrentBoarding)) && legs[$0].transitLeg == true
        }
    }

    /// True when the rider alights leg `index` and boards leg `index + 1` at the
    /// same stop — the "stay put, no street crossing" transfer.
    public func isSameStopTransfer(fromLegAt index: Int) -> Bool {
        guard index >= 0, index + 1 < legs.count,
              legs[index].transitLeg == true,
              legs[index + 1].transitLeg == true,
              let toStop = legs[index].to.stopId,
              let fromStop = legs[index + 1].from.stopId else {
            return false
        }
        return toStop == fromStop
    }

    /// The number of stops left before alighting leg `index`, estimated by
    /// elapsed time across the leg's intermediate stops. Includes the final stop,
    /// so the answer is at least 1 while the leg is underway.
    public func stopsRemaining(onLegAt index: Int) -> Int? {
        guard index >= 0, index < legs.count else { return nil }
        let leg = legs[index]
        guard leg.transitLeg == true else { return nil }

        let stopCount = (leg.intermediateStops?.count ?? 0) + 1

        guard now > leg.startTime else { return stopCount }
        guard now < leg.endTime else { return 0 }

        let fraction = now.timeIntervalSince(leg.startTime) / leg.endTime.timeIntervalSince(leg.startTime)
        let passed = Int(Double(stopCount) * fraction)
        return max(1, stopCount - passed)
    }

    /// The total number of stops the rider rides on leg `index`, counting the
    /// alighting stop.
    public func totalStops(onLegAt index: Int) -> Int? {
        guard index >= 0, index < legs.count, legs[index].transitLeg == true else { return nil }
        return (legs[index].intermediateStops?.count ?? 0) + 1
    }

    /// The walking sub-step the rider is likely on, estimated by elapsed time
    /// across the leg's steps.
    public func currentStep(onLegAt index: Int) -> Step? {
        guard index >= 0, index < legs.count else { return nil }
        let leg = legs[index]
        guard let steps = leg.steps, !steps.isEmpty else { return nil }

        let duration = leg.endTime.timeIntervalSince(leg.startTime)
        guard duration > 0 else { return nil }

        let fraction = min(0.999, max(0, now.timeIntervalSince(leg.startTime) / duration))
        return steps[Int(fraction * Double(steps.count))]
    }

    // MARK: - Progress Bar

    /// One segment of the trip progress bar.
    public struct Segment: Equatable {
        /// The leg this segment represents.
        public let legIndex: Int
        /// This leg's share of the total trip duration, 0...1.
        public let widthFraction: Double
        /// How much of this leg is behind the rider, 0...1.
        public let fillFraction: Double
        /// True when this leg is a transit leg (drawn in the route color).
        public let isTransit: Bool
        /// True when this leg is a rental ride (drawn in rental purple).
        public let isRental: Bool
    }

    /// Proportional segments for the tip-detent progress bar.
    public var segments: [Segment] {
        let durations = legs.map { $0.endTime.timeIntervalSince($0.startTime) }
        let totalDuration = durations.reduce(0, +)
        guard totalDuration > 0 else { return [] }

        return legs.enumerated().map { index, leg in
            let duration = durations[index]
            let fill: Double
            if now >= leg.endTime {
                fill = 1
            } else if now <= leg.startTime || duration <= 0 {
                fill = 0
            } else {
                fill = now.timeIntervalSince(leg.startTime) / duration
            }

            return Segment(
                legIndex: index,
                widthFraction: duration / totalDuration,
                fillFraction: fill,
                isTransit: leg.transitLeg == true,
                isRental: leg.isRentalRide
            )
        }
    }
}
