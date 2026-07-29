//
//  TripProgressTests.swift
//  OTPKit
//
//  Created by Claude on 7/28/26.
//

import Testing
import Foundation
@testable import OTPKit

/// Tests for the in-trip panel's clock-driven progress engine.
struct TripProgressTests {

    /// A fixed reference so phase math never depends on the wall clock.
    let tripStart = Date(timeIntervalSince1970: 1_753_000_000)

    // MARK: - Fixtures

    /// Walk 3m → wait 4m → ride 30m (5 intermediate stops) → walk 2m.
    func makeItinerary() -> Itinerary {
        let walkEnd = tripStart.addingTimeInterval(180)
        let busStart = tripStart.addingTimeInterval(420)
        let busEnd = busStart.addingTimeInterval(1800)
        let finalWalkEnd = busEnd.addingTimeInterval(120)

        let boardStop = Place(name: "Fauntleroy Way SW & SW Myrtle St", lon: -122.3, lat: 47.5,
                              vertexType: "STOP", stopId: "1_13860", stopCode: "13860")
        let alightStop = Place(name: "3rd Ave & Virginia St", lon: -122.33, lat: 47.61,
                               vertexType: "STOP", stopId: "1_431", stopCode: "431")

        let walkLeg = Leg(
            startTime: tripStart, endTime: walkEnd, mode: "WALK",
            routeType: nil, routeColor: nil, routeTextColor: nil, route: nil, agencyName: nil,
            from: Place(name: "Home", lon: -122.29, lat: 47.49, vertexType: "NORMAL"),
            to: boardStop,
            legGeometry: LegGeometry(points: "AA@@", length: 4),
            distance: 320, transitLeg: false, duration: 180, realTime: nil,
            streetNames: nil, pathway: nil, steps: nil, headsign: nil, intermediateStops: nil
        )

        let busLeg = Leg(
            startTime: busStart, endTime: busEnd, mode: "BUS",
            routeType: .bus, routeColor: "9C2136", routeTextColor: "FFFFFF",
            route: "C Line", agencyName: "Metro Transit",
            from: boardStop, to: alightStop,
            legGeometry: LegGeometry(points: "AA@@", length: 4),
            distance: 9000, transitLeg: true, duration: 1800, realTime: true,
            streetNames: nil, pathway: nil, steps: nil, headsign: "Downtown Seattle",
            intermediateStops: (1...5).map {
                Place(name: "Stop \($0)", lon: -122.3, lat: 47.5, vertexType: "STOP")
            },
            departureDelay: 0, arrivalDelay: 0
        )

        let finalWalkLeg = Leg(
            startTime: busEnd, endTime: finalWalkEnd, mode: "WALK",
            routeType: nil, routeColor: nil, routeTextColor: nil, route: nil, agencyName: nil,
            from: alightStop,
            to: Place(name: "Climate Pledge Arena", lon: -122.354, lat: 47.622, vertexType: "NORMAL"),
            legGeometry: LegGeometry(points: "AA@@", length: 4),
            distance: 145, transitLeg: false, duration: 120, realTime: nil,
            streetNames: nil, pathway: nil, steps: nil, headsign: nil, intermediateStops: nil
        )

        return Itinerary(
            duration: Int(finalWalkEnd.timeIntervalSince(tripStart)),
            startTime: tripStart,
            endTime: finalWalkEnd,
            walkTime: 300, transitTime: 1800, waitingTime: 240,
            walkDistance: 465, walkLimitExceeded: false,
            elevationLost: 0, elevationGained: 0,
            transfers: 0,
            legs: [walkLeg, busLeg, finalWalkLeg]
        )
    }

    func progress(at offset: TimeInterval) -> TripProgress {
        TripProgress(itinerary: makeItinerary(), now: tripStart.addingTimeInterval(offset))
    }

    // MARK: - Phase

    @Test func phaseBeforeTripStarts() {
        let progress = progress(at: -240)
        #expect(progress.phase == .notStarted)
        #expect(progress.secondsUntilStart == 240)
    }

    @Test func phaseWhileWalking() {
        #expect(progress(at: 60).phase == .walking(legIndex: 0))
    }

    @Test func phaseWhileWaitingAtStop() {
        // The walk is done but boarding hasn't happened: a distinct state, not a leg.
        #expect(progress(at: 300).phase == .waiting(boardingLegIndex: 1))
    }

    @Test func phaseWhileRiding() {
        #expect(progress(at: 1000).phase == .riding(legIndex: 1))
    }

    @Test func phaseDuringFinalWalk() {
        #expect(progress(at: 2280).phase == .walking(legIndex: 2))
    }

    @Test func phaseAfterArrival() {
        #expect(progress(at: 3000).phase == .arrived)
    }

    // MARK: - Rows

    @Test func noRowIsCurrentBeforeTheTripStarts() {
        // "No pip is green yet."
        let rows = progress(at: -240).rows
        #expect(rows.allSatisfy { $0.state != .current })
    }

    @Test func exactlyOneCurrentRowDuringTheTrip() {
        for offset in [60.0, 300, 1000, 2280] {
            let currentRows = progress(at: offset).rows.filter { $0.state == .current }
            #expect(currentRows.count == 1, "expected one current row at offset \(offset)")
        }
    }

    @Test func transitLegExpandsIntoBoardAndGetOffRows() {
        let ids = progress(at: -240).rows.map(\.id)
        #expect(ids == ["walk-0", "board-1", "getoff-1", "walk-2", "arrive"])
    }

    @Test func ridingInsertsASyntheticRideRow() {
        let rows = progress(at: 1000).rows
        #expect(rows.map(\.id) == ["walk-0", "board-1", "ride-1", "getoff-1", "walk-2", "arrive"])

        // The board row collapses to done once aboard; the ride row is the one now.
        #expect(rows.first { $0.id == "board-1" }?.state == .done)
        #expect(rows.first { $0.id == "ride-1" }?.state == .current)
    }

    @Test func waitingMakesTheBoardRowCurrent() {
        let rows = progress(at: 300).rows
        #expect(rows.first { $0.id == "board-1" }?.state == .current)
        #expect(rows.first { $0.id == "walk-0" }?.state == .done)
    }

    // MARK: - Rider Questions

    @Test func waitAfterWalkLeg() {
        #expect(progress(at: 0).waitAfterLeg(at: 0) == 240)
        #expect(progress(at: 0).waitAfterLeg(at: 1) == nil) // contiguous legs
    }

    @Test func stopsRemainingCountsDownAsTheRideElapses() {
        // 6 stops total (5 intermediate + alighting).
        #expect(progress(at: 300).stopsRemaining(onLegAt: 1) == 6)
        // Halfway through the ride, half the stops are behind the rider.
        #expect(progress(at: 420 + 900).stopsRemaining(onLegAt: 1) == 3)
        // Near the end there is always at least one stop left.
        #expect(progress(at: 420 + 1790).stopsRemaining(onLegAt: 1) == 1)
        // Walking legs have no stop count.
        #expect(progress(at: 300).stopsRemaining(onLegAt: 0) == nil)
    }

    @Test func sameStopTransferComparesStopIDs() {
        var progress = self.progress(at: 0)
        // Bus alights at 1_431; the final walk starts there, but it's not transit-to-transit.
        #expect(progress.isSameStopTransfer(fromLegAt: 0) == false)

        // Build a two-bus itinerary where leg 0 ends where leg 1 begins.
        let itinerary = makeItinerary()
        let sharedStop = itinerary.legs[1].to
        let secondBus = Leg(
            startTime: itinerary.legs[1].endTime.addingTimeInterval(360),
            endTime: itinerary.legs[1].endTime.addingTimeInterval(840),
            mode: "BUS", routeType: .bus, routeColor: "F0A83C", routeTextColor: nil,
            route: "2", agencyName: "Metro Transit",
            from: sharedStop,
            to: Place(name: "1st Ave N & Republican St", lon: -122.355, lat: 47.623, vertexType: "STOP"),
            legGeometry: LegGeometry(points: "AA@@", length: 4),
            distance: 2000, transitLeg: true, duration: 480, realTime: nil,
            streetNames: nil, pathway: nil, steps: nil, headsign: "W Queen Anne", intermediateStops: nil
        )
        let transferItinerary = Itinerary(
            duration: 3000, startTime: tripStart, endTime: secondBus.endTime,
            walkTime: 180, transitTime: 2280, waitingTime: 600,
            walkDistance: 320, walkLimitExceeded: false,
            elevationLost: 0, elevationGained: 0, transfers: 1,
            legs: [itinerary.legs[0], itinerary.legs[1], secondBus]
        )
        progress = TripProgress(itinerary: transferItinerary, now: tripStart)
        #expect(progress.isSameStopTransfer(fromLegAt: 1) == true)
    }

    @Test func currentStepAdvancesWithElapsedTime() {
        // Give the first walk leg two equal-weight steps.
        let itinerary = makeItinerary()
        var legs = itinerary.legs
        let walk = legs[0]
        legs[0] = Leg(
            startTime: walk.startTime, endTime: walk.endTime, mode: walk.mode,
            routeType: nil, routeColor: nil, routeTextColor: nil, route: nil, agencyName: nil,
            from: walk.from, to: walk.to, legGeometry: walk.legGeometry,
            distance: walk.distance, transitLeg: false, duration: walk.duration, realTime: nil,
            streetNames: nil, pathway: nil,
            steps: [
                Step(distance: 100, streetName: "45th Ave SW", relativeDirection: "DEPART",
                     elevationChange: nil, lon: -122.3, lat: 47.5),
                Step(distance: 120, streetName: "SW Myrtle St", relativeDirection: "RIGHT",
                     elevationChange: nil, lon: -122.3, lat: 47.5)
            ],
            headsign: nil, intermediateStops: nil
        )
        let stepped = Itinerary(
            duration: itinerary.duration, startTime: itinerary.startTime, endTime: itinerary.endTime,
            walkTime: itinerary.walkTime, transitTime: itinerary.transitTime,
            waitingTime: itinerary.waitingTime, walkDistance: itinerary.walkDistance,
            walkLimitExceeded: false, elevationLost: 0, elevationGained: 0,
            transfers: itinerary.transfers, legs: legs
        )

        // First half of the 180s walk → first step; second half → second step.
        let early = TripProgress(itinerary: stepped, now: tripStart.addingTimeInterval(30))
        #expect(early.currentStep(onLegAt: 0)?.streetName == "45th Ave SW")

        let late = TripProgress(itinerary: stepped, now: tripStart.addingTimeInterval(150))
        #expect(late.currentStep(onLegAt: 0)?.streetName == "SW Myrtle St")

        // Legs without steps have no current step.
        #expect(early.currentStep(onLegAt: 1) == nil)
    }

    // MARK: - Progress Bar

    @Test func segmentsAreProportionalAndFill() {
        let segments = progress(at: 90).segments
        #expect(segments.count == 3)
        #expect(abs(segments.map(\.widthFraction).reduce(0, +) - 1.0) < 0.001)

        // Half the first walk is behind the rider; nothing else is.
        #expect(abs(segments[0].fillFraction - 0.5) < 0.01)
        #expect(segments[1].fillFraction == 0)
        #expect(segments[1].isTransit)
    }

    // MARK: - Real-Time Status

    @Test func realTimeStatusMapping() {
        #expect(RealTimeStatus(realTime: nil, delaySeconds: nil) == .scheduled)
        #expect(RealTimeStatus(realTime: false, delaySeconds: 300) == .scheduled)
        #expect(RealTimeStatus(realTime: true, delaySeconds: 20) == .onTime)
        #expect(RealTimeStatus(realTime: true, delaySeconds: 420) == .late(minutes: 7))
        #expect(RealTimeStatus(realTime: true, delaySeconds: -120) == .early(minutes: 2))
    }

    @Test func legDelayFieldsDecodeFromRESTPayload() throws {
        let json = """
        {
            "startTime": 1753000000000,
            "endTime": 1753001800000,
            "mode": "BUS",
            "route": "C Line",
            "from": {"name": "A", "lon": -122.3, "lat": 47.5, "vertexType": "STOP"},
            "to": {"name": "B", "lon": -122.33, "lat": 47.61, "vertexType": "STOP"},
            "legGeometry": {"points": "AA@@", "length": 4},
            "distance": 9000,
            "transitLeg": true,
            "duration": 1800,
            "realTime": true,
            "departureDelay": 420,
            "arrivalDelay": 380
        }
        """
        let leg = try JSONDecoder.otpDecoder().decode(Leg.self, from: Data(json.utf8))
        #expect(leg.departureDelay == 420)
        #expect(leg.arrivalDelay == 380)
        #expect(leg.departureStatus == .late(minutes: 7))
        #expect(leg.arrivalStatus == .late(minutes: 6))
    }
}
