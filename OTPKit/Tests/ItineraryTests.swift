//
//  ItineraryTests.swift
//  OTPKitDemoTests
//
//  Created by Aaron Brethorst on 10/28/25.
//

import Testing
import MapKit
import CoreLocation
@testable import OTPKit

struct ItineraryTests {

    // MARK: - Test Helpers

    /// Creates a test itinerary with specified polyline coordinates
    func makeTestItinerary(legPolylines: [String]) -> Itinerary {
        let legs = legPolylines.map { polyline in
            Leg(
                startTime: Date(),
                endTime: Date().addingTimeInterval(600),
                mode: "WALK",
                routeType: nil,
                routeColor: nil,
                routeTextColor: nil,
                route: nil,
                agencyName: nil,
                from: Place(
                    name: "Start",
                    lon: 0,
                    lat: 0,
                    vertexType: "NORMAL",
                    stopId: nil,
                    stopCode: nil
                ),
                to: Place(
                    name: "End",
                    lon: 0,
                    lat: 0,
                    vertexType: "NORMAL",
                    stopId: nil,
                    stopCode: nil
                ),
                legGeometry: LegGeometry(points: polyline, length: 100),
                distance: 100,
                transitLeg: false,
                duration: 600,
                realTime: false,
                streetNames: nil,
                pathway: false,
                steps: nil,
                headsign: nil,
                intermediateStops: nil
            )
        }

        return Itinerary(
            duration: 600,
            startTime: Date(),
            endTime: Date().addingTimeInterval(600),
            walkTime: 10,
            transitTime: 0,
            waitingTime: 0,
            walkDistance: 100,
            walkLimitExceeded: false,
            elevationLost: 0,
            elevationGained: 0,
            transfers: 0,
            legs: legs
        )
    }

    // MARK: - Tests

    @Test("Bounding box returns nil for empty coordinates")
    func testBoundingBoxEmptyCoordinates() {
        // Create an itinerary with invalid/empty polylines
        let itinerary = makeTestItinerary(legPolylines: [""])

        #expect(itinerary.boundingBox == nil)
    }

    @Test("Bounding box for single coordinate")
    func testBoundingBoxSingleCoordinate() {
        // Encoded polyline for a single point at approximately (47.6062, -122.3321) - Seattle
        // Using Google Polyline encoding
        let polyline = "_p~iF~ps|U"
        let itinerary = makeTestItinerary(legPolylines: [polyline])

        guard let boundingBox = itinerary.boundingBox else {
            Issue.record("Expected non-nil bounding box for single coordinate")
            return
        }

        // For a single point, the bounding box should have minimal but non-zero dimensions
        #expect(boundingBox.size.width >= 0)
        #expect(boundingBox.size.height >= 0)
    }

    @Test("Bounding box for two coordinates")
    func testBoundingBoxTwoCoordinates() {
        // Create coordinates manually: Seattle to Portland
        // Seattle: 47.6062, -122.3321
        // Portland: 45.5152, -122.6784
        let coord1 = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
        let coord2 = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)

        // Encode coordinates to polyline
        let polyline = encodeCoordinates([coord1, coord2])
        let itinerary = makeTestItinerary(legPolylines: [polyline])

        guard let boundingBox = itinerary.boundingBox else {
            Issue.record("Expected non-nil bounding box for two coordinates")
            return
        }

        // Convert coordinates to map points to verify bounds
        let point1 = MKMapPoint(coord1)
        let point2 = MKMapPoint(coord2)

        let minX = min(point1.x, point2.x)
        let maxX = max(point1.x, point2.x)
        let minY = min(point1.y, point2.y)
        let maxY = max(point1.y, point2.y)

        let expectedWidth = maxX - minX
        let expectedHeight = maxY - minY

        #expect(abs(boundingBox.size.width - expectedWidth) < 0.1)
        #expect(abs(boundingBox.size.height - expectedHeight) < 0.1)
        #expect(abs(boundingBox.origin.x - minX) < 0.1)
        #expect(abs(boundingBox.origin.y - minY) < 0.1)
    }

    @Test("Bounding box for multiple legs with various coordinates")
    func testBoundingBoxMultipleLegs() {
        // Create a multi-leg trip across different locations
        // Leg 1: Seattle area
        let leg1Coords = [
            CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
            CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        ]

        // Leg 2: Slightly south
        let leg2Coords = [
            CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            CLLocationCoordinate2D(latitude: 47.6000, longitude: -122.3400)
        ]

        let polyline1 = encodeCoordinates(leg1Coords)
        let polyline2 = encodeCoordinates(leg2Coords)

        let itinerary = makeTestItinerary(legPolylines: [polyline1, polyline2])

        guard let boundingBox = itinerary.boundingBox else {
            Issue.record("Expected non-nil bounding box for multiple legs")
            return
        }

        // Verify the bounding box encompasses all coordinates
        let allCoords = leg1Coords + leg2Coords
        let allPoints = allCoords.map { MKMapPoint($0) }

        let minX = allPoints.map { $0.x }.min()!
        let maxX = allPoints.map { $0.x }.max()!
        let minY = allPoints.map { $0.y }.min()!
        let maxY = allPoints.map { $0.y }.max()!

        // Verify bounding box contains all points
        #expect(boundingBox.origin.x <= minX + 0.1)
        #expect(boundingBox.origin.y <= minY + 0.1)
        #expect(boundingBox.maxX >= maxX - 0.1)
        #expect(boundingBox.maxY >= maxY - 0.1)
    }

    @Test("Bounding box for coordinates spanning large area")
    func testBoundingBoxLargeArea() {
        // Test with coordinates spanning from west coast to east coast
        let westCoast = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321) // Seattle
        let eastCoast = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)  // NYC

        let polyline = encodeCoordinates([westCoast, eastCoast])
        let itinerary = makeTestItinerary(legPolylines: [polyline])

        guard let boundingBox = itinerary.boundingBox else {
            Issue.record("Expected non-nil bounding box for large area")
            return
        }

        // Verify the bounding box is substantial (spanning significant distance)
        #expect(boundingBox.size.width > 1_000_000) // Should be large
        #expect(boundingBox.size.height > 100_000)  // Should be large
    }

    @Test("Bounding box debug - verify actual route dimensions")
    func testBoundingBoxDebug() {
        // Create a realistic route similar to what's in the screenshot
        // Origin around Seattle area, with a short walk
        let walkCoords = [
            CLLocationCoordinate2D(latitude: 47.6805, longitude: -122.3321),
            CLLocationCoordinate2D(latitude: 47.6810, longitude: -122.3325),
            CLLocationCoordinate2D(latitude: 47.6815, longitude: -122.3330)
        ]

        let busCoords = [
            CLLocationCoordinate2D(latitude: 47.6815, longitude: -122.3330),
            CLLocationCoordinate2D(latitude: 47.6900, longitude: -122.3400),
            CLLocationCoordinate2D(latitude: 47.7000, longitude: -122.3500)
        ]

        let polyline1 = encodeCoordinates(walkCoords)
        let polyline2 = encodeCoordinates(busCoords)

        let itinerary = makeTestItinerary(legPolylines: [polyline1, polyline2])

        guard let boundingBox = itinerary.boundingBox else {
            Issue.record("Expected non-nil bounding box")
            return
        }

        // Print debug info
        print("Debug - Bounding box:")
        print("  Origin: (\(boundingBox.origin.x), \(boundingBox.origin.y))")
        print("  Size: (\(boundingBox.size.width), \(boundingBox.size.height))")
        print("  Width/Height ratio: \(boundingBox.size.width / boundingBox.size.height)")

        // Convert back to coordinates to verify
        let minCoord = boundingBox.origin.coordinate
        let maxCoord = MKMapPoint(x: boundingBox.maxX, y: boundingBox.maxY).coordinate

        print("  Min coordinate: (\(minCoord.latitude), \(minCoord.longitude))")
        print("  Max coordinate: (\(maxCoord.latitude), \(maxCoord.longitude))")

        // Verify the box makes sense
        #expect(boundingBox.size.width > 0)
        #expect(boundingBox.size.height > 0)

        // Verify all original coordinates are within the box (with tolerance for floating point)
        let allCoords = walkCoords + busCoords
        for coord in allCoords {
            let point = MKMapPoint(coord)
            // Check with a small tolerance due to floating-point precision
            let expanded = boundingBox.insetBy(dx: -1, dy: -1)
            #expect(expanded.contains(point), "Coordinate \(coord) should be within bounding box")
        }
    }

    // MARK: - relevantLegs Tests

    @Test("relevantLegs filters out short walks")
    func testRelevantLegsFiltersShortWalks() {
        let shortWalk = Leg(
            startTime: Date(),
            endTime: Date().addingTimeInterval(30),
            mode: "WALK",
            routeType: nil,
            routeColor: nil,
            routeTextColor: nil,
            route: nil,
            agencyName: nil,
            from: Place(name: "A", lon: 0, lat: 0, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            to: Place(name: "B", lon: 0, lat: 0, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            legGeometry: LegGeometry(points: "", length: 0),
            distance: 50,
            transitLeg: false,
            duration: 30, // Less than 60 seconds
            realTime: false,
            streetNames: nil,
            pathway: false,
            steps: nil,
            headsign: nil,
            intermediateStops: nil
        )

        let longWalk = Leg(
            startTime: Date(),
            endTime: Date().addingTimeInterval(120),
            mode: "WALK",
            routeType: nil,
            routeColor: nil,
            routeTextColor: nil,
            route: nil,
            agencyName: nil,
            from: Place(name: "C", lon: 0, lat: 0, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            to: Place(name: "D", lon: 0, lat: 0, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            legGeometry: LegGeometry(points: "", length: 0),
            distance: 100,
            transitLeg: false,
            duration: 120, // More than 60 seconds
            realTime: false,
            streetNames: nil,
            pathway: false,
            steps: nil,
            headsign: nil,
            intermediateStops: nil
        )

        let itinerary = Itinerary(
            duration: 150,
            startTime: Date(),
            endTime: Date().addingTimeInterval(150),
            walkTime: 2,
            transitTime: 0,
            waitingTime: 0,
            walkDistance: 150,
            walkLimitExceeded: false,
            elevationLost: 0,
            elevationGained: 0,
            transfers: 0,
            legs: [shortWalk, longWalk]
        )

        let relevant = itinerary.relevantLegs
        #expect(relevant.count == 1)
        #expect(relevant[0].duration == 120)
    }

    @Test("relevantLegs merges consecutive legs with same route")
    func testRelevantLegsMergesConsecutiveSameRoute() {
        let busLeg1 = Leg(
            startTime: Date(),
            endTime: Date().addingTimeInterval(300),
            mode: "BUS",
            routeType: .bus,
            routeColor: "FF0000",
            routeTextColor: "FFFFFF",
            route: "12",
            agencyName: "Metro",
            from: Place(name: "Stop A", lon: -122.3, lat: 47.6, vertexType: "NORMAL", stopId: "123", stopCode: "A"),
            to: Place(name: "Stop B", lon: -122.31, lat: 47.61, vertexType: "NORMAL", stopId: "124", stopCode: "B"),
            legGeometry: LegGeometry(points: "polyline1", length: 100),
            distance: 1000,
            transitLeg: true,
            duration: 300,
            realTime: true,
            streetNames: nil,
            pathway: false,
            steps: nil,
            headsign: "Downtown",
            intermediateStops: nil
        )

        let busLeg2 = Leg(
            startTime: Date().addingTimeInterval(300),
            endTime: Date().addingTimeInterval(600),
            mode: "BUS",
            routeType: .bus,
            routeColor: "FF0000",
            routeTextColor: "FFFFFF",
            route: "12", // Same route
            agencyName: "Metro",
            from: Place(name: "Stop B", lon: -122.31, lat: 47.61, vertexType: "NORMAL", stopId: "124", stopCode: "B"),
            to: Place(name: "Stop C", lon: -122.32, lat: 47.62, vertexType: "NORMAL", stopId: "125", stopCode: "C"),
            legGeometry: LegGeometry(points: "polyline2", length: 100),
            distance: 1000,
            transitLeg: true,
            duration: 300,
            realTime: true,
            streetNames: nil,
            pathway: false,
            steps: nil,
            headsign: "Downtown",
            intermediateStops: nil
        )

        let itinerary = Itinerary(
            duration: 600,
            startTime: Date(),
            endTime: Date().addingTimeInterval(600),
            walkTime: 0,
            transitTime: 10,
            waitingTime: 0,
            walkDistance: 0,
            walkLimitExceeded: false,
            elevationLost: 0,
            elevationGained: 0,
            transfers: 0,
            legs: [busLeg1, busLeg2]
        )

        let relevant = itinerary.relevantLegs
        #expect(relevant.count == 1, "Should merge two consecutive legs with same route")

        let mergedLeg = relevant[0]
        #expect(mergedLeg.route == "12")
        #expect(mergedLeg.from.name == "Stop A", "Should keep first leg's start point")
        #expect(mergedLeg.to.name == "Stop C", "Should keep last leg's end point")
        #expect(mergedLeg.duration == 600, "Should combine durations")
        #expect(mergedLeg.distance == 2000, "Should combine distances")
        #expect(mergedLeg.startTime == busLeg1.startTime, "Should keep first leg's start time")
        #expect(mergedLeg.endTime == busLeg2.endTime, "Should keep last leg's end time")
    }

    @Test("relevantLegs does not merge different routes")
    func testRelevantLegsDoesNotMergeDifferentRoutes() {
        let busLeg1 = Leg(
            startTime: Date(),
            endTime: Date().addingTimeInterval(300),
            mode: "BUS",
            routeType: .bus,
            routeColor: nil,
            routeTextColor: nil,
            route: "12",
            agencyName: "Metro",
            from: Place(name: "Stop A", lon: -122.3, lat: 47.6, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            to: Place(name: "Stop B", lon: -122.31, lat: 47.61, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            legGeometry: LegGeometry(points: "", length: 0),
            distance: 1000,
            transitLeg: true,
            duration: 300,
            realTime: false,
            streetNames: nil,
            pathway: false,
            steps: nil,
            headsign: nil,
            intermediateStops: nil
        )

        let busLeg2 = Leg(
            startTime: Date().addingTimeInterval(300),
            endTime: Date().addingTimeInterval(600),
            mode: "BUS",
            routeType: .bus,
            routeColor: nil,
            routeTextColor: nil,
            route: "10", // Different route
            agencyName: "Metro",
            from: Place(name: "Stop B", lon: -122.31, lat: 47.61, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            to: Place(name: "Stop C", lon: -122.32, lat: 47.62, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            legGeometry: LegGeometry(points: "", length: 0),
            distance: 1000,
            transitLeg: true,
            duration: 300,
            realTime: false,
            streetNames: nil,
            pathway: false,
            steps: nil,
            headsign: nil,
            intermediateStops: nil
        )

        let itinerary = Itinerary(
            duration: 600,
            startTime: Date(),
            endTime: Date().addingTimeInterval(600),
            walkTime: 0,
            transitTime: 10,
            waitingTime: 0,
            walkDistance: 0,
            walkLimitExceeded: false,
            elevationLost: 0,
            elevationGained: 0,
            transfers: 0,
            legs: [busLeg1, busLeg2]
        )

        let relevant = itinerary.relevantLegs
        #expect(relevant.count == 2, "Should not merge legs with different routes")
        #expect(relevant[0].route == "12")
        #expect(relevant[1].route == "10")
    }

    @Test("relevantLegs handles mixed walk and transit legs correctly")
    func testRelevantLegsHandlesMixedLegs() {
        let walk = Leg(
            startTime: Date(),
            endTime: Date().addingTimeInterval(120),
            mode: "WALK",
            routeType: nil,
            routeColor: nil,
            routeTextColor: nil,
            route: nil,
            agencyName: nil,
            from: Place(name: "Start", lon: -122.3, lat: 47.6, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            to: Place(name: "Stop A", lon: -122.31, lat: 47.61, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            legGeometry: LegGeometry(points: "", length: 0),
            distance: 100,
            transitLeg: false,
            duration: 120,
            realTime: false,
            streetNames: nil,
            pathway: false,
            steps: nil,
            headsign: nil,
            intermediateStops: nil
        )

        let bus1 = Leg(
            startTime: Date().addingTimeInterval(120),
            endTime: Date().addingTimeInterval(420),
            mode: "BUS",
            routeType: .bus,
            routeColor: nil,
            routeTextColor: nil,
            route: "12",
            agencyName: "Metro",
            from: Place(name: "Stop A", lon: -122.31, lat: 47.61, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            to: Place(name: "Stop B", lon: -122.32, lat: 47.62, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            legGeometry: LegGeometry(points: "", length: 0),
            distance: 1000,
            transitLeg: true,
            duration: 300,
            realTime: false,
            streetNames: nil,
            pathway: false,
            steps: nil,
            headsign: nil,
            intermediateStops: nil
        )

        let bus2 = Leg(
            startTime: Date().addingTimeInterval(420),
            endTime: Date().addingTimeInterval(720),
            mode: "BUS",
            routeType: .bus,
            routeColor: nil,
            routeTextColor: nil,
            route: "12", // Same route as bus1
            agencyName: "Metro",
            from: Place(name: "Stop B", lon: -122.32, lat: 47.62, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            to: Place(name: "Stop C", lon: -122.33, lat: 47.63, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            legGeometry: LegGeometry(points: "", length: 0),
            distance: 1000,
            transitLeg: true,
            duration: 300,
            realTime: false,
            streetNames: nil,
            pathway: false,
            steps: nil,
            headsign: nil,
            intermediateStops: nil
        )

        let itinerary = Itinerary(
            duration: 720,
            startTime: Date(),
            endTime: Date().addingTimeInterval(720),
            walkTime: 2,
            transitTime: 10,
            waitingTime: 0,
            walkDistance: 100,
            walkLimitExceeded: false,
            elevationLost: 0,
            elevationGained: 0,
            transfers: 0,
            legs: [walk, bus1, bus2]
        )

        let relevant = itinerary.relevantLegs
        #expect(relevant.count == 2, "Should have walk leg and merged bus leg")
        #expect(relevant[0].mode == "WALK")
        #expect(relevant[1].route == "12")
        #expect(relevant[1].duration == 600, "Bus legs should be merged")
    }

    @Test("relevantLegs does not merge legs with nil route")
    func testRelevantLegsDoesNotMergeNilRoutes() {
        let leg1 = Leg(
            startTime: Date(),
            endTime: Date().addingTimeInterval(300),
            mode: "BUS",
            routeType: .bus,
            routeColor: nil,
            routeTextColor: nil,
            route: nil, // No route
            agencyName: nil,
            from: Place(name: "A", lon: 0, lat: 0, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            to: Place(name: "B", lon: 0, lat: 0, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            legGeometry: LegGeometry(points: "", length: 0),
            distance: 1000,
            transitLeg: true,
            duration: 300,
            realTime: false,
            streetNames: nil,
            pathway: false,
            steps: nil,
            headsign: nil,
            intermediateStops: nil
        )

        let leg2 = Leg(
            startTime: Date().addingTimeInterval(300),
            endTime: Date().addingTimeInterval(600),
            mode: "BUS",
            routeType: .bus,
            routeColor: nil,
            routeTextColor: nil,
            route: nil, // No route
            agencyName: nil,
            from: Place(name: "B", lon: 0, lat: 0, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            to: Place(name: "C", lon: 0, lat: 0, vertexType: "NORMAL", stopId: nil, stopCode: nil),
            legGeometry: LegGeometry(points: "", length: 0),
            distance: 1000,
            transitLeg: true,
            duration: 300,
            realTime: false,
            streetNames: nil,
            pathway: false,
            steps: nil,
            headsign: nil,
            intermediateStops: nil
        )

        let itinerary = Itinerary(
            duration: 600,
            startTime: Date(),
            endTime: Date().addingTimeInterval(600),
            walkTime: 0,
            transitTime: 10,
            waitingTime: 0,
            walkDistance: 0,
            walkLimitExceeded: false,
            elevationLost: 0,
            elevationGained: 0,
            transfers: 0,
            legs: [leg1, leg2]
        )

        let relevant = itinerary.relevantLegs
        #expect(relevant.count == 2, "Should not merge legs with nil routes")
    }

    // MARK: - Helper Methods

    /// Simple polyline encoder for test purposes
    private func encodeCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> String {
        return OTPKit.encodeCoordinates(coordinates)
    }
}
