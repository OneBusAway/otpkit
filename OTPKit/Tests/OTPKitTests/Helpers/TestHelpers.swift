//
//  TestHelpers.swift
//  OTPKit
//
//  Created by Manu on 2025-08-12.
//

import XCTest
import CoreLocation
import MapKit
import SwiftUI
@testable import OTPKit

// MARK: - Test Fixtures

enum TestHelpers {

    /// Make a simple `Location` for tests
    static func location(
        title: String = "Place",
        subTitle: String = "",
        lat: CLLocationDegrees = 37.78,
        lon: CLLocationDegrees = -122.41
    ) -> Location {
        Location(title: title, subTitle: subTitle, latitude: lat, longitude: lon)
    }

    /// Make a minimal `Itinerary` for preview/selection tests
    static func itinerary() -> Itinerary {
        let now = Date()
        let leg = Leg(
            startTime: now,
            endTime: now.addingTimeInterval(300),
            mode: "WALK",
            routeType: .nonTransit,
            routeColor: nil,
            routeTextColor: nil,
            route: nil,
            agencyName: nil,
            from: Place(name: "A", lon: -122.0, lat: 47.0, vertexType: "NORMAL"),
            to: Place(name: "B", lon: -122.1, lat: 47.1, vertexType: "NORMAL"),
            legGeometry: LegGeometry(points: "", length: 0),
            distance: 100,
            transitLeg: false,
            duration: 300,
            realTime: nil,
            streetNames: nil,
            pathway: nil,
            steps: nil,
            headsign: nil
        )

        return Itinerary(
            duration: 300,
            startTime: now,
            endTime: now.addingTimeInterval(300),
            walkTime: 300,
            transitTime: 0,
            waitingTime: 0,
            walkDistance: 100,
            walkLimitExceeded: false,
            elevationLost: 0,
            elevationGained: 0,
            transfers: 0,
            legs: [leg]
        )
    }

    /// Wrap itineraries into an `OTPResponse` the view model expects
    static func response(with itineraries: [Itinerary]) -> OTPResponse {
        let plan = Plan(
            date: Date(),
            from: Place(name: "A", lon: -122.0, lat: 47.0, vertexType: "NORMAL"),
            to: Place(name: "B", lon: -122.1, lat: 47.1, vertexType: "NORMAL"),
            itineraries: itineraries
        )
        let params = RequestParameters(
            fromPlace: "a",
            toPlace: "b",
            time: "now",
            date: "today",
            mode: "WALK",
            arriveBy: "false",
            maxWalkDistance: "1000",
            wheelchair: "false"
        )
        return OTPResponse(requestParameters: params, plan: plan, error: nil)
    }
}
