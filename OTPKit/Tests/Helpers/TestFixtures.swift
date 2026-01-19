//
//  TestFixtures.swift
//  OTPKitTests
//
//  Test fixtures for OTPKit tests
//

import Foundation
import CoreLocation
import MapKit
@testable import OTPKit

/// Provides test fixtures for OTPKit tests
enum TestFixtures {

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

            // Return mock response or create a minimal one
            if let response = mockResponse {
                return response
            }

            // Create minimal valid response
            let requestParams = RequestParameters(
                fromPlace: request.origin.formattedForAPI,
                toPlace: request.destination.formattedForAPI,
                time: "12:00:00",
                date: "2024-01-01",
                mode: request.transportModesString,
                arriveBy: String(request.arriveBy),
                maxWalkDistance: String(request.maxWalkDistance),
                wheelchair: String(request.wheelchairAccessible)
            )

            return OTPResponse(
                requestParameters: requestParams,
                plan: nil,
                error: nil
            )
        }

        func reset() {
            shouldThrowError = false
            mockResponse = nil
            fetchPlanCallCount = 0
            lastRequest = nil
        }
    }

    // MARK: - Simple Fixture Builders

    static func makePlace(name: String = "Test") -> Place {
        return Place(name: name, lon: -122, lat: 47, vertexType: "TRANSIT")
    }

    /// Seattle region for tests (matches common test coordinates)
    static let seattleRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
        latitudinalMeters: 50000,
        longitudinalMeters: 50000
    )

    static func makeOTPConfiguration(
        serverURL: URL = URL(string: "https://otp.example.com")!,
        enabledModes: [TransportMode] = [.transit, .walk],
        theme: OTPThemeConfiguration? = nil,
        searchRegion: MKCoordinateRegion? = nil
    ) -> OTPConfiguration {
        OTPConfiguration(
            otpServerURL: serverURL,
            enabledTransportModes: enabledModes,
            themeConfiguration: theme ?? OTPThemeConfiguration(),
            searchRegion: searchRegion ?? seattleRegion
        )
    }

    static func makeLocation(
        name: String = "Test Location",
        lat: CLLocationDegrees = 37.7749,
        lon: CLLocationDegrees = -122.4194
    ) -> Location {
        // Use the existing TestHelpers
        return TestHelpers.location(title: name, lat: lat, lon: lon)
    }

    static func makeTripPlanRequest(
        origin: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        destination: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
        date: Date = Date(),
        time: Date = Date(),
        transportModes: [TransportMode] = [.transit, .walk],
        maxWalkDistance: Double = 804.672,
        wheelchairAccessible: Bool = false,
        arriveBy: Bool = false
    ) -> TripPlanRequest {
        TripPlanRequest(
            origin: origin,
            destination: destination,
            date: date,
            time: time,
            transportModes: transportModes,
            maxWalkDistance: Int(maxWalkDistance),
            wheelchairAccessible: wheelchairAccessible,
            arriveBy: arriveBy
        )
    }
}
