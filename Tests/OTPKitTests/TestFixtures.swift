//
//  TestFixtures.swift
//  OTPKitTests
//
//  Test data builders and fixtures for OTPKit tests
//

import Foundation
import CoreLocation
@testable import OTPKit

/// Provides fixture builders for OTPKit models
enum TestFixtures {

    // MARK: - Configuration Fixtures

    static func makeOTPConfiguration(
        serverURL: URL = URL(string: "https://otp.example.com")!,
        enabledModes: Set<TransportMode> = [.transit, .walk],
        theme: OTPThemeConfiguration? = nil
    ) -> OTPConfiguration {
        OTPConfiguration(
            otpServerURL: serverURL,
            enabledTransportModes: enabledModes,
            themeConfiguration: theme ?? OTPThemeConfiguration()
        )
    }

    // MARK: - Location Fixtures

    static func makePlace(
        name: String = "Test Location",
        lat: Double = 37.7749,
        lon: Double = -122.4194,
        stopId: String? = nil,
        stopCode: String? = nil
    ) -> Place {
        Place(
            name: name,
            lat: lat,
            lon: lon,
            stopId: stopId,
            stopCode: stopCode
        )
    }

    static func makeOriginPlace() -> Place {
        makePlace(name: "Origin", lat: 37.7749, lon: -122.4194)
    }

    static func makeDestinationPlace() -> Place {
        makePlace(name: "Destination", lat: 37.7849, lon: -122.4094)
    }

    static func makeLocation(
        coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        name: String = "Test Location",
        address: String? = "123 Test St"
    ) -> Location {
        Location(
            coordinate: coordinate,
            name: name,
            address: address
        )
    }

    // MARK: - Trip Planning Fixtures

    static func makeTripPlanRequest(
        fromPlace: String = "37.7749,-122.4194",
        toPlace: String = "37.7849,-122.4094",
        time: String? = nil,
        date: String? = nil,
        mode: String = "TRANSIT,WALK",
        arriveBy: Bool = false,
        maxWalkDistance: Double = 804.672,
        wheelchair: Bool = false
    ) -> TripPlanRequest {
        TripPlanRequest(
            fromPlace: fromPlace,
            toPlace: toPlace,
            time: time,
            date: date,
            mode: mode,
            arriveBy: arriveBy,
            maxWalkDistance: maxWalkDistance,
            wheelchair: wheelchair
        )
    }

    static func makeLeg(
        mode: String = "WALK",
        routeShortName: String? = nil,
        routeLongName: String? = nil,
        routeColor: String? = nil,
        routeTextColor: String? = nil,
        agencyName: String? = nil,
        from: Place? = nil,
        to: Place? = nil,
        startTime: Int64 = 1609459200000, // 2021-01-01 00:00:00 UTC
        endTime: Int64 = 1609459800000,   // 2021-01-01 00:10:00 UTC
        distance: Double = 500.0,
        duration: Int = 600,
        legGeometry: Polyline? = nil
    ) -> Leg {
        Leg(
            mode: mode,
            route: routeShortName,
            routeLongName: routeLongName,
            routeColor: routeColor,
            routeTextColor: routeTextColor,
            agencyName: agencyName,
            from: from ?? makeOriginPlace(),
            to: to ?? makeDestinationPlace(),
            startTime: startTime,
            endTime: endTime,
            distance: distance,
            duration: duration,
            legGeometry: legGeometry ?? makePolyline()
        )
    }

    static func makeWalkLeg(
        distance: Double = 500.0,
        duration: Int = 600
    ) -> Leg {
        makeLeg(
            mode: "WALK",
            distance: distance,
            duration: duration
        )
    }

    static func makeTransitLeg(
        mode: String = "BUS",
        routeShortName: String = "1",
        routeLongName: String = "Mission",
        routeColor: String = "FF0000",
        agencyName: String = "Test Transit"
    ) -> Leg {
        makeLeg(
            mode: mode,
            routeShortName: routeShortName,
            routeLongName: routeLongName,
            routeColor: routeColor,
            routeTextColor: "FFFFFF",
            agencyName: agencyName
        )
    }

    static func makeItinerary(
        legs: [Leg]? = nil,
        startTime: Int64 = 1609459200000,
        endTime: Int64 = 1609462800000,
        duration: Int = 3600,
        walkDistance: Double = 1000.0,
        walkTime: Int = 1200,
        transitTime: Int = 2400,
        waitingTime: Int = 0,
        transfers: Int = 1
    ) -> Itinerary {
        Itinerary(
            legs: legs ?? [makeWalkLeg(), makeTransitLeg(), makeWalkLeg()],
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            walkDistance: walkDistance,
            walkTime: walkTime,
            transitTime: transitTime,
            waitingTime: waitingTime,
            transfers: transfers
        )
    }

    static func makePolyline(
        points: String = "encoded_polyline_string",
        length: Int = 100
    ) -> Polyline {
        Polyline(points: points, length: length)
    }

    static func makePlan(
        itineraries: [Itinerary]? = nil
    ) -> Plan {
        Plan(
            from: makeOriginPlace(),
            to: makeDestinationPlace(),
            itineraries: itineraries ?? [makeItinerary()]
        )
    }

    static func makeOTPResponse(
        plan: Plan? = nil,
        error: OTPError? = nil
    ) -> OTPResponse {
        OTPResponse(
            plan: plan ?? makePlan(),
            error: error
        )
    }

    // MARK: - Mock API Service

    /// Mock APIService implementation for testing
    class MockAPIService: APIService {
        var shouldThrowError = false
        var mockError: Error = NSError(domain: "test", code: -1)
        var mockResponse: OTPResponse?
        var fetchPlanCallCount = 0
        var lastRequest: TripPlanRequest?

        func fetchPlan(_ request: TripPlanRequest) async throws -> OTPResponse {
            fetchPlanCallCount += 1
            lastRequest = request

            if shouldThrowError {
                throw mockError
            }

            return mockResponse ?? makeOTPResponse()
        }

        func reset() {
            shouldThrowError = false
            mockResponse = nil
            fetchPlanCallCount = 0
            lastRequest = nil
        }
    }
}
