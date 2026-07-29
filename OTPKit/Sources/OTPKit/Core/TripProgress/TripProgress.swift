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

    /// The rider is aboard a transit leg.
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
        /// The final destination.
        case arrive
    }

    public enum State: Equatable {
        /// Behind the rider. Collapses to one line at reduced opacity.
        case done
        /// Where the rider is. Exactly one row per trip, rendered as the now-card.
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
        case .walk(let index), .board(let index), .ride(let index), .getOff(let index):
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

        if now >= itinerary.endTime, let lastLeg = legs.last, now >= lastLeg.endTime {
            return .arrived
        }

        for (index, leg) in legs.enumerated() {
            // Inside the leg's own time window.
            if now >= leg.startTime && now < leg.endTime {
                return leg.transitLeg == true ? .riding(legIndex: index) : .walking(legIndex: index)
            }

            // In the gap between this leg and the next: waiting if the next leg
            // is transit (the rider is at the stop), otherwise treat the gap as
            // part of the upcoming walk.
            if now < leg.startTime {
                return leg.transitLeg == true ? .waiting(boardingLegIndex: index) : .walking(legIndex: index)
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

                if case .riding(let ridingIndex) = phase, ridingIndex == index {
                    rows.append(
                        RailRow(
                            id: "ride-\(index)",
                            kind: .ride(legIndex: index),
                            state: .current,
                            time: now,
                            status: nil
                        )
                    )
                }

                rows.append(getOffRow(for: leg, at: index, phase: phase))
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

    private func getOffRow(for leg: Leg, at index: Int, phase: TripPhase) -> RailRow {
        RailRow(
            id: "getoff-\(index)",
            kind: .getOff(legIndex: index),
            state: now >= leg.endTime ? .done : .upcoming,
            time: leg.endTime,
            status: nil
        )
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
    public func waitAfterLeg(at index: Int) -> TimeInterval? {
        guard index >= 0, index + 1 < legs.count else { return nil }
        let gap = legs[index + 1].startTime.timeIntervalSince(legs[index].endTime)
        return gap > 60 ? gap : nil
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
    }

    /// Proportional segments for the tip-detent progress bar.
    public var segments: [Segment] {
        let totalDuration = legs.reduce(0.0) { $0 + Double($1.duration) }
        guard totalDuration > 0 else { return [] }

        return legs.enumerated().map { index, leg in
            let duration = leg.endTime.timeIntervalSince(leg.startTime)
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
                widthFraction: Double(leg.duration) / totalDuration,
                fillFraction: fill,
                isTransit: leg.transitLeg == true
            )
        }
    }
}
