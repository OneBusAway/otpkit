//
//  RestAPIServiceComprehensiveTests.swift
//  OTPKitTests
//
//  Comprehensive tests for RestAPIService
//

import Testing
import Foundation
import CoreLocation
@testable import OTPKit

@Suite("RestAPIService Comprehensive Tests")
struct RestAPIServiceComprehensiveTests {

    // MARK: - URL Normalization Tests

    @Test("normalizeBaseURL adds routers/default when missing")
    func normalizeBaseURLAddsRoutersDefault() {
        let service = RestAPIService(baseURL: URL(string: "https://otp.example.com/otp")!)
        #expect(service.baseURL.absoluteString == "https://otp.example.com/otp/routers/default")
    }

    @Test("normalizeBaseURL preserves existing routers path")
    func normalizeBaseURLPreservesExistingRouters() {
        let service = RestAPIService(baseURL: URL(string: "https://otp.example.com/otp/routers/custom")!)
        #expect(service.baseURL.absoluteString == "https://otp.example.com/otp/routers/custom")
    }

    @Test("normalizeBaseURL handles routers/default already present")
    func normalizeBaseURLHandlesDefaultRouterPresent() {
        let service = RestAPIService(baseURL: URL(string: "https://otp.example.com/otp/routers/default")!)
        #expect(service.baseURL.absoluteString == "https://otp.example.com/otp/routers/default")
    }

    @Test("normalizeBaseURL handles trailing slash")
    func normalizeBaseURLHandlesTrailingSlash() {
        let service = RestAPIService(baseURL: URL(string: "https://otp.example.com/otp/")!)
        #expect(service.baseURL.absoluteString.contains("routers/default"))
    }

    @Test("normalizeBaseURL handles no path")
    func normalizeBaseURLHandlesNoPath() {
        let service = RestAPIService(baseURL: URL(string: "https://otp.example.com")!)
        #expect(service.baseURL.absoluteString.contains("routers/default"))
    }

    @Test("normalizeBaseURL with different router name")
    func normalizeBaseURLWithDifferentRouterName() {
        let service = RestAPIService(baseURL: URL(string: "https://otp.example.com/otp/routers/production")!)
        #expect(service.baseURL.absoluteString == "https://otp.example.com/otp/routers/production")
    }

    // MARK: - buildURL Tests

    @Test("buildURL appends endpoint")
    func buildURLAppendsEndpoint() {
        let service = RestAPIService(baseURL: URL(string: "https://otp.example.com/otp")!)
        let url = service.buildURL(endpoint: "plan")
        #expect(url.absoluteString.hasSuffix("/plan"))
    }

    @Test("buildURL handles different endpoints")
    func buildURLHandlesDifferentEndpoints() {
        let service = RestAPIService(baseURL: URL(string: "https://otp.example.com/otp")!)

        let planURL = service.buildURL(endpoint: "plan")
        #expect(planURL.absoluteString.contains("/plan"))

        let indexURL = service.buildURL(endpoint: "index")
        #expect(indexURL.absoluteString.contains("/index"))
    }

    @Test("buildURL produces valid URL")
    func buildURLProducesValidURL() {
        let service = RestAPIService(baseURL: URL(string: "https://otp.example.com/otp")!)
        let url = service.buildURL(endpoint: "plan")
        #expect(url.scheme == "https")
        #expect(url.host == "otp.example.com")
    }

    // MARK: - Successful API Call Tests

    @Test("fetchPlan with TripPlanRequest succeeds")
    func fetchPlanWithTripPlanRequestSucceeds() async throws {
        let mockLoader = MockDataLoader()
        let fixtureData = try loadFixture(named: "otp_response_success")
        mockLoader.mockResponse(data: fixtureData)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        let response = try await service.fetchPlan(request)

        #expect(response.plan != nil)
        #expect(response.plan?.itineraries.count == 1)
    }

    @Test("fetchPlan includes all query parameters")
    func fetchPlanIncludesAllQueryParameters() async throws {
        let mockLoader = MockDataLoader()
        let fixtureData = try loadFixture(named: "otp_response_success")
        mockLoader.mockResponse(data: fixtureData)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date(),
            transportModes: [.transit, .walk],
            maxWalkDistance: 1500,
            wheelchairAccessible: true,
            arriveBy: true
        )

        _ = try await service.fetchPlan(request)

        let urlString = mockLoader.lastRequest!.url!.absoluteString
        #expect(urlString.contains("fromPlace="))
        #expect(urlString.contains("toPlace="))
        #expect(urlString.contains("mode="))
        #expect(urlString.contains("maxWalkDistance=1500"))
        #expect(urlString.contains("wheelchair=true"))
        #expect(urlString.contains("arriveBy=true"))
    }

    @Test("fetchPlan with wheelchair accessible parameter")
    func fetchPlanWithWheelchairAccessible() async throws {
        let mockLoader = MockDataLoader()
        let fixtureData = try loadFixture(named: "otp_response_success")
        mockLoader.mockResponse(data: fixtureData)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date(),
            wheelchairAccessible: true
        )

        _ = try await service.fetchPlan(request)

        let urlString = mockLoader.lastRequest!.url!.absoluteString
        #expect(urlString.contains("wheelchair=true"))
    }

    @Test("fetchPlan with arriveBy parameter")
    func fetchPlanWithArriveBy() async throws {
        let mockLoader = MockDataLoader()
        let fixtureData = try loadFixture(named: "otp_response_success")
        mockLoader.mockResponse(data: fixtureData)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date(),
            arriveBy: true
        )

        _ = try await service.fetchPlan(request)

        let urlString = mockLoader.lastRequest!.url!.absoluteString
        #expect(urlString.contains("arriveBy=true"))
    }

    @Test("fetchPlan with bike transport mode")
    func fetchPlanWithBikeTransportMode() async throws {
        let mockLoader = MockDataLoader()
        let fixtureData = try loadFixture(named: "otp_response_success")
        mockLoader.mockResponse(data: fixtureData)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date(),
            transportModes: [.bike]
        )

        _ = try await service.fetchPlan(request)

        let urlString = mockLoader.lastRequest!.url!.absoluteString
        #expect(urlString.contains("mode=BIKE"))
    }

    @Test("fetchPlan with multiple transport modes")
    func fetchPlanWithMultipleTransportModes() async throws {
        let mockLoader = MockDataLoader()
        let fixtureData = try loadFixture(named: "otp_response_success")
        mockLoader.mockResponse(data: fixtureData)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date(),
            transportModes: [.transit, .walk, .bike]
        )

        _ = try await service.fetchPlan(request)

        let urlString = mockLoader.lastRequest!.url!.absoluteString
        #expect(urlString.contains("mode=TRANSIT,WALK,BIKE"))
    }

    @Test("fetchPlan with custom maxWalkDistance")
    func fetchPlanWithCustomMaxWalkDistance() async throws {
        let mockLoader = MockDataLoader()
        let fixtureData = try loadFixture(named: "otp_response_success")
        mockLoader.mockResponse(data: fixtureData)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date(),
            maxWalkDistance: 2000
        )

        _ = try await service.fetchPlan(request)

        let urlString = mockLoader.lastRequest!.url!.absoluteString
        #expect(urlString.contains("maxWalkDistance=2000"))
    }

    // MARK: - Empty Response Tests

    @Test("fetchPlan with empty itineraries")
    func fetchPlanWithEmptyItineraries() async throws {
        let mockLoader = MockDataLoader()
        let fixtureData = try loadFixture(named: "otp_response_empty")
        mockLoader.mockResponse(data: fixtureData)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        let response = try await service.fetchPlan(request)

        #expect(response.plan != nil)
        #expect(response.plan?.itineraries.isEmpty == true)
    }

    // MARK: - Error Response Tests

    @Test("fetchPlan with OTP error response")
    func fetchPlanWithOTPErrorResponse() async throws {
        let mockLoader = MockDataLoader()
        let fixtureData = try loadFixture(named: "otp_response_error")
        mockLoader.mockResponse(data: fixtureData)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        let response = try await service.fetchPlan(request)

        #expect(response.plan == nil)
        #expect(response.error != nil)
        #expect(response.error?.message == "No trip found that satisfies the requested parameters.")
    }

    // MARK: - HTTP Error Tests

    @Test("fetchPlan throws on HTTP 404")
    func fetchPlanThrowsOnHTTP404() async throws {
        let mockLoader = MockDataLoader()
        mockLoader.mockResponse(data: Data(), statusCode: 404)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        await #expect(throws: Error.self) {
            try await service.fetchPlan(request)
        }
    }

    @Test("fetchPlan throws on HTTP 500")
    func fetchPlanThrowsOnHTTP500() async throws {
        let mockLoader = MockDataLoader()
        mockLoader.mockResponse(data: Data(), statusCode: 500)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        await #expect(throws: Error.self) {
            try await service.fetchPlan(request)
        }
    }

    @Test("fetchPlan throws on HTTP 400")
    func fetchPlanThrowsOnHTTP400() async throws {
        let mockLoader = MockDataLoader()
        mockLoader.mockResponse(data: Data(), statusCode: 400)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        await #expect(throws: Error.self) {
            try await service.fetchPlan(request)
        }
    }

    @Test("fetchPlan throws on HTTP 503")
    func fetchPlanThrowsOnHTTP503() async throws {
        let mockLoader = MockDataLoader()
        mockLoader.mockResponse(data: Data(), statusCode: 503)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        await #expect(throws: Error.self) {
            try await service.fetchPlan(request)
        }
    }

    @Test("fetchPlan succeeds on HTTP 200")
    func fetchPlanSucceedsOnHTTP200() async throws {
        let mockLoader = MockDataLoader()
        let fixtureData = try loadFixture(named: "otp_response_success")
        mockLoader.mockResponse(data: fixtureData, statusCode: 200)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        let response = try await service.fetchPlan(request)
        #expect(response.plan != nil)
    }

    // MARK: - Malformed Response Tests

    @Test("fetchPlan throws on invalid JSON")
    func fetchPlanThrowsOnInvalidJSON() async throws {
        let mockLoader = MockDataLoader()
        let invalidJSON = "{ this is not valid JSON }".data(using: .utf8)!
        mockLoader.mockResponse(data: invalidJSON)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        await #expect(throws: Error.self) {
            try await service.fetchPlan(request)
        }
    }

    @Test("fetchPlan throws on empty data")
    func fetchPlanThrowsOnEmptyData() async throws {
        let mockLoader = MockDataLoader()
        mockLoader.mockResponse(data: Data())

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        await #expect(throws: Error.self) {
            try await service.fetchPlan(request)
        }
    }

    // MARK: - Direct fetchPlan Method Tests

    @Test("fetchPlan direct method constructs correct URL")
    func fetchPlanDirectMethodConstructsCorrectURL() async throws {
        let mockLoader = MockDataLoader()
        let fixtureData = try loadFixture(named: "otp_response_success")
        mockLoader.mockResponse(data: fixtureData)

        let service = RestAPIService(
            baseURL: URL(string: "https://otp.example.com")!,
            dataLoader: mockLoader
        )

        _ = try await service.fetchPlan(
            fromPlace: "47.6097,-122.3331",
            toPlace: "47.6154,-122.3208",
            time: "08:00:00",
            date: "2024-05-10",
            mode: "TRANSIT,WALK",
            arriveBy: false,
            maxWalkDistance: 1000,
            wheelchair: false
        )

        let urlString = mockLoader.lastRequest!.url!.absoluteString
        #expect(urlString.contains("fromPlace=47.6097,-122.3331"))
        #expect(urlString.contains("toPlace=47.6154,-122.3208"))
        #expect(urlString.contains("time=08:00:00"))
        #expect(urlString.contains("date=2024-05-10"))
        #expect(urlString.contains("mode=TRANSIT,WALK"))
        #expect(urlString.contains("arriveBy=false"))
        #expect(urlString.contains("maxWalkDistance=1000"))
        #expect(urlString.contains("wheelchair=false"))
    }

    // MARK: - Helper Methods

    private func loadFixture(named name: String) throws -> Data {
        let bundle = Bundle(for: Fixtures.self)
        guard let path = bundle.path(forResource: name, ofType: "json") else {
            throw NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Fixture \(name).json not found"])
        }
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }
}
