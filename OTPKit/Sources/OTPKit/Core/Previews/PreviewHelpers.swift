//
//  PreviewHelpers.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 8/5/24.
//

import CoreLocation
import MapKit
import SwiftUI

class PreviewHelpers {

    static func mockOTPConfiguration() -> OTPConfiguration {
        return OTPConfiguration(
            otpServerURL: URL(string: "https://example.com")!
        )
    }

    @MainActor
    static func mockTripPlannerViewModel() -> TripPlannerViewModel {
        let config = OTPConfiguration(
            otpServerURL: URL(string: "https://example.com")!
        )
        let mapView = MKMapView()
        let mapProvider = MKMapViewAdapter(mapView: mapView)
        let mapCoordinator = MapCoordinator(mapProvider: mapProvider)
        return TripPlannerViewModel(config: config, apiService: MockAPIService(), mapCoordinator: mapCoordinator)
    }

    public class MockAPIService: APIService {
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

    static func buildItin(legsCount: Int = 1) -> Itinerary {
        var legs: [Leg] = []
        for _ in 0..<legsCount {
            legs.append(buildWalkLeg())
            legs.append(buildLeg())
        }

        legs.append(buildWalkLeg())

        return Itinerary(
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
            legs: legs
        )
    }

    static func buildWalkLeg() -> Leg {
        Leg(startTime: Date(), endTime: Date(), mode: "WALK", routeType: nil, routeColor: nil, routeTextColor: nil, route: nil, agencyName: nil, from: Place(name: "foo", lon: 47, lat: -122, vertexType: ""), to: Place(name: "foo", lon: 47, lat: -122, vertexType: ""), legGeometry: LegGeometry(points: "AA@@", length: 4), distance: 100, transitLeg: false, duration: 60, realTime: true, streetNames: nil, pathway: nil, steps: nil, headsign: nil)
    }

    static func buildLeg(route: String? = nil, agencyName: String? = nil) -> Leg {
        Leg(
            startTime: Date(),
            endTime: Date(),
            mode: "TRAM",
            routeType: .tram,
            routeColor: "FFFFFF",
            routeTextColor: "000000",
            route: route ?? String(Int.random(in: 1...999)),
            agencyName: agencyName,
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
            headsign: "woot"
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
