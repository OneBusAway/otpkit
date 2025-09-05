//
//  PreviewHelpers.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/5/24.
//

import CoreLocation
import MapKit
import SwiftUI
import os.log

class PreviewHelpers {

    static func mockOTPConfiguration() -> OTPConfiguration {
        return OTPConfiguration(
            otpServerURL: URL(string: "https://example.com")!,
            region: .automatic
        )
    }

    static func mockTripPlannerViewModel() -> TripPlannerViewModel {
        let config = OTPConfiguration(
            otpServerURL: URL(string: "https://example.com")!,
            region: .automatic
        )
        return TripPlannerViewModel(config: config, apiService: MockAPIService())
    }

    public class MockAPIService: APIService {
        public var logger: os.Logger = os.Logger(subsystem: "otpkit", category: "MockAPIService")

        func fetchPlan(_ request: TripPlanRequest) async throws -> OTPResponse {
            return OTPResponse(
                requestParameters: RequestParameters(
                    fromPlace: "0,0",
                    toPlace: "1,1",
                    time: "12:00",
                    date: "2024-01-01",
                    mode: "TRANSIT",
                    arriveBy: "false",
                    maxWalkDistance: "1000",
                    wheelchair: "false"
                ),
                plan: nil,
                error: nil
            )
        }
    }

    static func buildItin() -> Itinerary {
        Itinerary(
            duration: 1800,
            startTime: Date(),
            endTime: Date().addingTimeInterval(1800),
            walkTime: 600,
            transitTime: 1200,
            waitingTime: 0,
            walkDistance: 800.0,
            walkLimitExceeded: false,
            elevationLost: 0.0,
            elevationGained: 0.0,
            transfers: 1,
            legs: [buildLeg()]
        )
    }

    static func buildLeg() -> Leg {
        Leg(
            startTime: Date(),
            endTime: Date(),
            mode: "TRAM",
            route: nil,
            agencyName: nil,
            from: Place(name: "foo", lon: 47, lat: -122, vertexType: ""),
            to: Place(name: "foo", lon: 47, lat: -122, vertexType: ""),
            legGeometry: LegGeometry(points: "AA@@", length: 4),
            distance: 100,
            transitLeg: false,
            duration: 10,
            realTime: true,
            streetNames: nil,
            pathway: nil,
            steps: nil,
            headsign: nil
        )
    }

    static func createOrigin() -> Location {
        return Location(
            title: "Starbucks Reserve Roastery",
            subTitle: "1124 Pike St, Seattle, WA",
            latitude: 47.6131,
            longitude: -122.3260
        )
    }

    static func createDestination() -> Location {
        Location(
            title: "Space Needle",
            subTitle: "400 Broad St, Seattle, WA",
            latitude: 47.6205,
            longitude: -122.3493
        )
    }
}
