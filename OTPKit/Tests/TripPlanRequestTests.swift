//
//  TripPlanRequestTests.swift
//  OTPKitTests
//
//  Comprehensive tests for TripPlanRequest model
//

import Testing
import CoreLocation
@testable import OTPKit

@Suite("TripPlanRequest Tests")
struct TripPlanRequestTests {

    // MARK: - Initialization Tests

    @Test("Init with default values")
    func initWithDefaults() {
        let origin = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        let destination = CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208)
        let date = Date()
        let time = Date()

        let request = TripPlanRequest(
            origin: origin,
            destination: destination,
            date: date,
            time: time
        )

        #expect(request.origin.latitude == origin.latitude)
        #expect(request.origin.longitude == origin.longitude)
        #expect(request.destination.latitude == destination.latitude)
        #expect(request.destination.longitude == destination.longitude)
        #expect(request.date == date)
        #expect(request.time == time)
        #expect(request.transportModes == [.transit, .walk]) // Default
        #expect(request.maxWalkDistance == 1000) // Default
        #expect(!request.wheelchairAccessible) // Default
        #expect(!request.arriveBy) // Default
    }

    @Test("Init with custom values")
    func initWithCustomValues() {
        let origin = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        let destination = CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208)
        let date = Date()
        let time = Date()

        let request = TripPlanRequest(
            origin: origin,
            destination: destination,
            date: date,
            time: time,
            transportModes: [.bike, .walk, .transit],
            maxWalkDistance: 1500,
            wheelchairAccessible: true,
            arriveBy: true
        )

        #expect(request.transportModes == [.bike, .walk, .transit])
        #expect(request.maxWalkDistance == 1500)
        #expect(request.wheelchairAccessible)
        #expect(request.arriveBy)
    }

    @Test("Init with single transport mode")
    func initWithSingleTransportMode() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            destination: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            date: Date(),
            time: Date(),
            transportModes: [.bike]
        )

        #expect(request.transportModes == [.bike])
    }

    // MARK: - transportModesString Tests

    @Test("transportModesString with single mode")
    func transportModesStringSingleMode() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            destination: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            date: Date(),
            time: Date(),
            transportModes: [.walk]
        )

        #expect(request.transportModesString == "WALK")
    }

    @Test("transportModesString with multiple modes")
    func transportModesStringMultipleModes() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            destination: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            date: Date(),
            time: Date(),
            transportModes: [.transit, .walk, .bike]
        )

        #expect(request.transportModesString == "TRANSIT,WALK,BIKE")
    }

    @Test("transportModesString with default modes")
    func transportModesStringDefaultModes() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            destination: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            date: Date(),
            time: Date()
        )

        #expect(request.transportModesString == "TRANSIT,WALK")
    }

    // MARK: - isValid() Tests

    @Test("isValid with valid coordinates")
    func isValidWithValidCoordinates() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        #expect(request.isValid())
    }

    @Test("isValid with origin latitude too high")
    func isValidWithOriginLatitudeTooHigh() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 91.0, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        #expect(!request.isValid())
    }

    @Test("isValid with origin latitude too low")
    func isValidWithOriginLatitudeTooLow() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: -91.0, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        #expect(!request.isValid())
    }

    @Test("isValid with origin longitude too high")
    func isValidWithOriginLongitudeTooHigh() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: 181.0),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        #expect(!request.isValid())
    }

    @Test("isValid with origin longitude too low")
    func isValidWithOriginLongitudeTooLow() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -181.0),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        #expect(!request.isValid())
    }

    @Test("isValid with destination latitude too high")
    func isValidWithDestinationLatitudeTooHigh() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 91.0, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        #expect(!request.isValid())
    }

    @Test("isValid with destination latitude too low")
    func isValidWithDestinationLatitudeTooLow() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: -91.0, longitude: -122.3208),
            date: Date(),
            time: Date()
        )

        #expect(!request.isValid())
    }

    @Test("isValid with destination longitude too high")
    func isValidWithDestinationLongitudeTooHigh() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: 181.0),
            date: Date(),
            time: Date()
        )

        #expect(!request.isValid())
    }

    @Test("isValid with destination longitude too low")
    func isValidWithDestinationLongitudeTooLow() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -181.0),
            date: Date(),
            time: Date()
        )

        #expect(!request.isValid())
    }

    @Test("isValid with edge case latitude 90")
    func isValidWithEdgeCaseLatitude90() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 90.0, longitude: 0.0),
            destination: CLLocationCoordinate2D(latitude: -90.0, longitude: 0.0),
            date: Date(),
            time: Date()
        )

        #expect(request.isValid())
    }

    @Test("isValid with edge case longitude 180")
    func isValidWithEdgeCaseLongitude180() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 0.0, longitude: 180.0),
            destination: CLLocationCoordinate2D(latitude: 0.0, longitude: -180.0),
            date: Date(),
            time: Date()
        )

        #expect(request.isValid())
    }

    @Test("isValid with zero maxWalkDistance")
    func isValidWithZeroMaxWalkDistance() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            destination: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            date: Date(),
            time: Date(),
            maxWalkDistance: 0
        )

        #expect(!request.isValid())
    }

    @Test("isValid with negative maxWalkDistance")
    func isValidWithNegativeMaxWalkDistance() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            destination: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            date: Date(),
            time: Date(),
            maxWalkDistance: -100
        )

        #expect(!request.isValid())
    }

    @Test("isValid with positive maxWalkDistance")
    func isValidWithPositiveMaxWalkDistance() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            destination: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            date: Date(),
            time: Date(),
            maxWalkDistance: 1000
        )

        #expect(request.isValid())
    }

    @Test("isValid with empty transport modes")
    func isValidWithEmptyTransportModes() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            destination: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            date: Date(),
            time: Date(),
            transportModes: []
        )

        #expect(!request.isValid())
    }

    @Test("isValid with one transport mode")
    func isValidWithOneTransportMode() {
        let request = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            destination: CLLocationCoordinate2D(latitude: 1, longitude: 1),
            date: Date(),
            time: Date(),
            transportModes: [.walk]
        )

        #expect(request.isValid())
    }

    // MARK: - Hashable Tests

    @Test("Hash produces consistent values")
    func hashProducesConsistentValues() {
        let origin = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        let destination = CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208)
        let date = Date()
        let time = Date()

        let request1 = TripPlanRequest(origin: origin, destination: destination, date: date, time: time)
        let request2 = TripPlanRequest(origin: origin, destination: destination, date: date, time: time)

        #expect(request1.hashValue == request2.hashValue)
    }

    @Test("Different requests have different hashes")
    func differentRequestsHaveDifferentHashes() {
        let origin = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        let destination = CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208)
        let date = Date()
        let time = Date()

        let request1 = TripPlanRequest(origin: origin, destination: destination, date: date, time: time)
        let request2 = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 48.0, longitude: -123.0),
            destination: destination,
            date: date,
            time: time
        )

        #expect(request1.hashValue != request2.hashValue)
    }

    // MARK: - Equatable Tests

    @Test("Identical requests are equal")
    func identicalRequestsAreEqual() {
        let origin = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        let destination = CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208)
        let date = Date()
        let time = Date()

        let request1 = TripPlanRequest(origin: origin, destination: destination, date: date, time: time)
        let request2 = TripPlanRequest(origin: origin, destination: destination, date: date, time: time)

        #expect(request1 == request2)
    }

    @Test("Requests with different origins are not equal")
    func requestsWithDifferentOriginsAreNotEqual() {
        let destination = CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208)
        let date = Date()
        let time = Date()

        let request1 = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: destination,
            date: date,
            time: time
        )
        let request2 = TripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 48.0, longitude: -123.0),
            destination: destination,
            date: date,
            time: time
        )

        #expect(request1 != request2)
    }

    @Test("Requests with different destinations are not equal")
    func requestsWithDifferentDestinationsAreNotEqual() {
        let origin = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        let date = Date()
        let time = Date()

        let request1 = TripPlanRequest(
            origin: origin,
            destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
            date: date,
            time: time
        )
        let request2 = TripPlanRequest(
            origin: origin,
            destination: CLLocationCoordinate2D(latitude: 48.0, longitude: -123.0),
            date: date,
            time: time
        )

        #expect(request1 != request2)
    }

    @Test("Requests with different transport modes are not equal")
    func requestsWithDifferentTransportModesAreNotEqual() {
        let origin = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        let destination = CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208)
        let date = Date()
        let time = Date()

        let request1 = TripPlanRequest(
            origin: origin,
            destination: destination,
            date: date,
            time: time,
            transportModes: [.walk]
        )
        let request2 = TripPlanRequest(
            origin: origin,
            destination: destination,
            date: date,
            time: time,
            transportModes: [.bike]
        )

        #expect(request1 != request2)
    }

    @Test("Requests with different maxWalkDistance are not equal")
    func requestsWithDifferentMaxWalkDistanceAreNotEqual() {
        let origin = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        let destination = CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208)
        let date = Date()
        let time = Date()

        let request1 = TripPlanRequest(
            origin: origin,
            destination: destination,
            date: date,
            time: time,
            maxWalkDistance: 1000
        )
        let request2 = TripPlanRequest(
            origin: origin,
            destination: destination,
            date: date,
            time: time,
            maxWalkDistance: 1500
        )

        #expect(request1 != request2)
    }

    @Test("Requests with different wheelchair settings are not equal")
    func requestsWithDifferentWheelchairSettingsAreNotEqual() {
        let origin = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        let destination = CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208)
        let date = Date()
        let time = Date()

        let request1 = TripPlanRequest(
            origin: origin,
            destination: destination,
            date: date,
            time: time,
            wheelchairAccessible: false
        )
        let request2 = TripPlanRequest(
            origin: origin,
            destination: destination,
            date: date,
            time: time,
            wheelchairAccessible: true
        )

        #expect(request1 != request2)
    }

    @Test("Requests with different arriveBy settings are not equal")
    func requestsWithDifferentArriveBySettingsAreNotEqual() {
        let origin = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        let destination = CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208)
        let date = Date()
        let time = Date()

        let request1 = TripPlanRequest(
            origin: origin,
            destination: destination,
            date: date,
            time: time,
            arriveBy: false
        )
        let request2 = TripPlanRequest(
            origin: origin,
            destination: destination,
            date: date,
            time: time,
            arriveBy: true
        )

        #expect(request1 != request2)
    }

    // MARK: - CLLocationCoordinate2D Extension Tests

    @Test("formattedForAPI with positive coordinates")
    func formattedForAPIWithPositiveCoordinates() {
        let coordinate = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)
        let formatted = coordinate.formattedForAPI

        #expect(formatted == "47.6097,-122.3331")
    }

    @Test("formattedForAPI with negative coordinates")
    func formattedForAPIWithNegativeCoordinates() {
        let coordinate = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
        let formatted = coordinate.formattedForAPI

        #expect(formatted == "-33.8688,151.2093")
    }

    @Test("formattedForAPI with zero coordinates")
    func formattedForAPIWithZeroCoordinates() {
        let coordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let formatted = coordinate.formattedForAPI

        #expect(formatted == "0.0000,0.0000")
    }

    @Test("formattedForAPI precision is 4 decimal places")
    func formattedForAPIPrecision() {
        let coordinate = CLLocationCoordinate2D(latitude: 47.609756789, longitude: -122.333123456)
        let formatted = coordinate.formattedForAPI

        #expect(formatted == "47.6098,-122.3331")
    }

    @Test("CLLocationCoordinate2D Codable roundtrip")
    func coordinateCodableRoundtrip() throws {
        let original = CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CLLocationCoordinate2D.self, from: data)

        #expect(decoded.latitude == original.latitude)
        #expect(decoded.longitude == original.longitude)
    }
}
