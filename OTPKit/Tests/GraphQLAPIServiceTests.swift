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

@testable import OTPKit
import XCTest
import CoreLocation

class GraphQLAPIServiceTests: OTPTestCase {

    private var service: GraphQLAPIService!
    private var mockDataLoader: MockDataLoader!

    override func setUp() {
        super.setUp()
        service = buildGraphQLAPIService()
        mockDataLoader = (service.dataLoader as? MockDataLoader)!
    }

    // MARK: - Endpoint URL

    func testEndpointURLFromOTPRoot() {
        let service = buildGraphQLAPIService(baseURLString: "https://sound-transit-otp.ibi-transit.com/otp/")
        XCTAssertEqual(service.endpointURL.absoluteString, "https://sound-transit-otp.ibi-transit.com/otp/gtfs/v1")
    }

    func testEndpointURLStripsRoutersPath() {
        let service = buildGraphQLAPIService(baseURLString: "https://otp.example.com/otp/routers/default/")
        XCTAssertEqual(service.endpointURL.absoluteString, "https://otp.example.com/otp/gtfs/v1")
    }

    func testEndpointURLAlreadyPointsAtGraphQL() {
        let service = buildGraphQLAPIService(baseURLString: "https://otp.example.com/otp/gtfs/v1")
        XCTAssertEqual(service.endpointURL.absoluteString, "https://otp.example.com/otp/gtfs/v1")
    }

    // MARK: - Request Building

    func testFetchPlanSendsGraphQLRequest() async throws {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_plan_success.json"))

        _ = try await service.fetchPlan(createTripPlanRequest())

        let request = try XCTUnwrap(mockDataLoader.lastRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://sound-transit-otp.ibi-transit.com/otp/gtfs/v1")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.httpBody)
        let payload = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let query = try XCTUnwrap(payload["query"] as? String)
        XCTAssertTrue(query.contains("plan("))

        let variables = try XCTUnwrap(payload["variables"] as? [String: Any])
        let from = try XCTUnwrap(variables["from"] as? [String: Any])
        XCTAssertEqual(from["lat"] as? Double, 47.6097)
        XCTAssertEqual(from["lon"] as? Double, -122.3331)
        let to = try XCTUnwrap(variables["to"] as? [String: Any])
        XCTAssertEqual(to["lat"] as? Double, 47.6205)
        XCTAssertEqual(to["lon"] as? Double, -122.3493)
        XCTAssertEqual(variables["date"] as? String, "05-10-2024")
        XCTAssertEqual(variables["time"] as? String, "8:00 AM")
        XCTAssertEqual(variables["arriveBy"] as? Bool, false)
        XCTAssertEqual(variables["wheelchair"] as? Bool, false)
        XCTAssertEqual(variables["maxWalkDistance"] as? Double, 800)

        let modes = try XCTUnwrap(variables["transportModes"] as? [[String: Any]])
        XCTAssertEqual(modes.map { $0["mode"] as? String }, ["TRANSIT", "WALK"])
    }

    func testFetchPlanMapsBikeModeToGraphQLBicycle() async throws {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_plan_success.json"))

        _ = try await service.fetchPlan(createTripPlanRequest(transportModes: [.bike, .walk]))

        let request = try XCTUnwrap(mockDataLoader.lastRequest)
        let body = try XCTUnwrap(request.httpBody)
        let payload = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let variables = try XCTUnwrap(payload["variables"] as? [String: Any])
        let modes = try XCTUnwrap(variables["transportModes"] as? [[String: Any]])
        // The GraphQL Mode enum spells it BICYCLE; TransportMode.bike.rawValue ("BIKE") is a REST-only token.
        XCTAssertEqual(modes.map { $0["mode"] as? String }, ["BICYCLE", "WALK"])
    }

    func testFetchPlanSendsBikeRentalQualifier() async throws {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_plan_success.json"))

        _ = try await service.fetchPlan(createTripPlanRequest(transportModes: [.bikeRental, .walk]))

        let request = try XCTUnwrap(mockDataLoader.lastRequest)
        let body = try XCTUnwrap(request.httpBody)
        let payload = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let variables = try XCTUnwrap(payload["variables"] as? [String: Any])
        let modes = try XCTUnwrap(variables["transportModes"] as? [[String: Any]])
        // BICYCLE_RENT is a REST-only token; GraphQL expresses rentals as a qualified BICYCLE.
        XCTAssertEqual(modes.map { $0["mode"] as? String }, ["BICYCLE", "WALK"])
        XCTAssertEqual(modes[0]["qualifier"] as? String, "RENT")
        XCTAssertNil(modes[1]["qualifier"])
    }

    // MARK: - Response Mapping

    func testFetchPlanMapsItineraries() async throws {
        let response = try await fetchSuccessPlan()

        XCTAssertNil(response.error)
        let plan = try XCTUnwrap(response.plan)
        XCTAssertEqual(plan.date, Date(timeIntervalSince1970: 1_785_340_800))
        XCTAssertEqual(plan.from.name, "Origin")
        XCTAssertEqual(plan.to.name, "Destination")
        XCTAssertEqual(plan.itineraries.count, 3)

        let itinerary = plan.itineraries[0]
        XCTAssertEqual(itinerary.duration, 775)
        XCTAssertEqual(itinerary.startTime, Date(timeIntervalSince1970: 1_785_341_233))
        XCTAssertEqual(itinerary.endTime, Date(timeIntervalSince1970: 1_785_342_008))
        XCTAssertEqual(itinerary.walkTime, 595)
        XCTAssertEqual(itinerary.waitingTime, 0)
        XCTAssertEqual(itinerary.transitTime, 180)
        XCTAssertEqual(itinerary.walkDistance, 626.6, accuracy: 0.01)
        XCTAssertEqual(itinerary.transfers, 0)
        XCTAssertFalse(itinerary.walkLimitExceeded)
        XCTAssertEqual(itinerary.legs.count, 3)
    }

    func testFetchPlanMapsTransitLeg() async throws {
        let response = try await fetchSuccessPlan()

        let leg = try XCTUnwrap(response.plan?.itineraries[0].legs[1])
        XCTAssertEqual(leg.mode, "MONORAIL")
        XCTAssertEqual(leg.route, "Monorail")
        XCTAssertEqual(leg.agencyName, "Seattle Center Monorail")
        // GTFS extended route type 12 has no RouteType case; it must degrade to nil, not fail decoding.
        XCTAssertNil(leg.routeType)
        XCTAssertEqual(leg.transitLeg, true)
        XCTAssertEqual(leg.headsign, "Seattle Center")
        XCTAssertEqual(leg.duration, 180)
        XCTAssertEqual(leg.distance, 1507.0)
        XCTAssertEqual(leg.startTime, Date(timeIntervalSince1970: 1_785_341_700))
        XCTAssertEqual(leg.from.name, "Westlake Center")
        XCTAssertEqual(leg.from.stopId, "96:WL")
        XCTAssertEqual(leg.from.vertexType, "TRANSIT")
        XCTAssertEqual(leg.to.stopId, "96:SC")
        XCTAssertFalse(leg.legGeometry.points.isEmpty)
    }

    func testFetchPlanMapsBusLegWithIntermediateStops() async throws {
        let response = try await fetchSuccessPlan()

        let leg = try XCTUnwrap(response.plan?.itineraries[1].legs[1])
        XCTAssertEqual(leg.mode, "BUS")
        XCTAssertEqual(leg.route, "33")
        XCTAssertEqual(leg.routeType, .bus)
        XCTAssertEqual(leg.intermediateStops?.count, 4)
        XCTAssertNotNil(leg.intermediateStops?.first?.stopId)
    }

    func testFetchPlanMapsWalkLegSteps() async throws {
        let response = try await fetchSuccessPlan()

        let leg = try XCTUnwrap(response.plan?.itineraries[0].legs[0])
        XCTAssertEqual(leg.mode, "WALK")
        XCTAssertTrue(leg.walkMode)
        XCTAssertNil(leg.route)
        let step = try XCTUnwrap(leg.steps?.first)
        XCTAssertEqual(step.streetName, "6th Avenue")
        XCTAssertEqual(step.relativeDirection, "DEPART")
        XCTAssertEqual(step.distance, 60.61, accuracy: 0.01)
    }

    func testFetchPlanSynthesizesRequestParameters() async throws {
        let response = try await fetchSuccessPlan()

        let params = response.requestParameters
        XCTAssertEqual(params.fromPlace, "47.6097,-122.3331")
        XCTAssertEqual(params.toPlace, "47.6205,-122.3493")
        XCTAssertEqual(params.date, "05-10-2024")
        XCTAssertEqual(params.time, "8:00 AM")
        XCTAssertEqual(params.mode, "TRANSIT,WALK")
        XCTAssertEqual(params.arriveBy, "false")
        XCTAssertEqual(params.maxWalkDistance, "800")
        XCTAssertEqual(params.wheelchair, "false")
    }

    func testFetchPlanMapsRentalLegs() async throws {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_plan_rental.json"))

        let response = try await service.fetchPlan(createTripPlanRequest(transportModes: [.bikeRental, .walk]))

        let legs = try XCTUnwrap(response.plan?.itineraries.first?.legs)
        XCTAssertEqual(legs.count, 2)

        let walkLeg = legs[0]
        XCTAssertEqual(walkLeg.mode, "WALK")
        XCTAssertEqual(walkLeg.rentedBike, false)
        XCTAssertNil(walkLeg.from.bikeShareId)
        // The walk leg ends at the free-floating vehicle being picked up.
        XCTAssertEqual(walkLeg.to.bikeShareId, "lime_seattle:9e18440a-e282-4ac5-94d0-2659f6311bed")

        let rideLeg = legs[1]
        XCTAssertEqual(rideLeg.mode, "BICYCLE")
        XCTAssertEqual(rideLeg.rentedBike, true)
        XCTAssertEqual(rideLeg.from.bikeShareId, "lime_seattle:9e18440a-e282-4ac5-94d0-2659f6311bed")
        // Docked dropoff maps the station id into the same field.
        XCTAssertEqual(rideLeg.to.bikeShareId, "pronto:BT-01")
    }

    // MARK: - Vehicle Rentals

    func testFetchVehicleRentalsSendsRequest() async throws {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_rentals_mixed.json"))

        _ = try await service.fetchVehicleRentals(in: seattleBoundingBox, formFactors: nil)

        let request = try XCTUnwrap(mockDataLoader.lastRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://sound-transit-otp.ibi-transit.com/otp/gtfs/v1")

        let body = try XCTUnwrap(request.httpBody)
        let payload = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let query = try XCTUnwrap(payload["query"] as? String)
        XCTAssertTrue(query.contains("vehicleRentalsByBbox("))

        let variables = try XCTUnwrap(payload["variables"] as? [String: Any])
        XCTAssertEqual(variables["minLat"] as? Double, 47.5)
        XCTAssertEqual(variables["maxLat"] as? Double, 47.7)
        XCTAssertEqual(variables["minLon"] as? Double, -122.4)
        XCTAssertEqual(variables["maxLon"] as? Double, -122.2)
    }

    func testFetchVehicleRentalsMapsStationsAndVehicles() async throws {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_rentals_mixed.json"))

        let result = try await service.fetchVehicleRentals(in: seattleBoundingBox, formFactors: nil)

        XCTAssertEqual(result.rentals.count, 5)
        XCTAssertTrue(result.partialErrors.isEmpty)

        guard case .station(let station) = result.rentals[0] else {
            return XCTFail("Expected first entity to be a station")
        }
        XCTAssertEqual(station.stationId, "pronto:BT-01")
        XCTAssertEqual(station.name, "Pine St & 9th Ave")
        XCTAssertEqual(station.vehiclesAvailableCount, 3)
        XCTAssertEqual(station.docksAvailableCount, 15)
        XCTAssertTrue(station.isOperative)
        XCTAssertEqual(station.rentalUris?.ios, "https://pronto.example.com/stations/BT-01")

        guard case .vehicle(let vehicle) = result.rentals[1] else {
            return XCTFail("Expected second entity to be a vehicle")
        }
        XCTAssertEqual(vehicle.vehicleId, "lime_seattle:9f8b7460-b06e-4e2e-bbd4-01b40bbdbc0d")
        XCTAssertEqual(vehicle.vehicleType?.formFactor, .bicycle)
        // Battery is absent on the live Seattle feed; range is the reliable stat.
        XCTAssertNil(vehicle.fuel?.percent)
        XCTAssertEqual(vehicle.fuel?.range, 26602)
        XCTAssertNil(vehicle.rentalUris)
    }

    func testFetchVehicleRentalsUnknownFormFactorDecodesAsOther() async throws {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_rentals_mixed.json"))

        let result = try await service.fetchVehicleRentals(in: seattleBoundingBox, formFactors: nil)

        guard case .vehicle(let hoverboard) = result.rentals[3] else {
            return XCTFail("Expected fourth entity to be a vehicle")
        }
        // A form factor OTP adds later must degrade to .other, never fail the whole decode.
        XCTAssertEqual(hoverboard.vehicleType?.formFactor, .other)
        XCTAssertFalse(hoverboard.isOperative)
    }

    func testFetchVehicleRentalsFiltersBicycles() async throws {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_rentals_mixed.json"))

        let result = try await service.fetchVehicleRentals(
            in: seattleBoundingBox,
            formFactors: [.bicycle, .cargoBicycle]
        )

        // Station stocks bicycles, one vehicle is a bicycle, and the untyped vehicle
        // is included fail-open. The scooter and the unknown form factor are excluded.
        XCTAssertEqual(result.rentals.map(\.id), [
            "pronto:BT-01",
            "lime_seattle:9f8b7460-b06e-4e2e-bbd4-01b40bbdbc0d",
            "mystery_wheels:untyped-1"
        ])
    }

    func testFetchVehicleRentalsFiltersScooters() async throws {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_rentals_mixed.json"))

        let result = try await service.fetchVehicleRentals(
            in: seattleBoundingBox,
            formFactors: [.scooter, .scooterSeated, .scooterStanding]
        )

        // The bicycle-only station is excluded; the untyped vehicle is fail-open included.
        XCTAssertEqual(result.rentals.map(\.id), [
            "lime_seattle:2a919739-89e2-48e4-a3d8-dfbd2a29f674",
            "mystery_wheels:untyped-1"
        ])
    }

    func testFetchVehicleRentalsPartialSuccessReturnsDataAndErrors() async throws {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_rentals_partial_error.json"))

        let result = try await service.fetchVehicleRentals(in: seattleBoundingBox, formFactors: nil)

        XCTAssertEqual(result.rentals.count, 1)
        XCTAssertEqual(result.partialErrors.count, 1)
        XCTAssertTrue(result.partialErrors[0].contains("timed out"))
    }

    func testFetchVehicleRentalsThrowsOnTopLevelGraphQLError() async throws {
        let errorJSON = """
        {"errors":[{"message":"Validation error: unknown field"}]}
        """
        mockDataLoader.mockResponse(data: Data(errorJSON.utf8))

        do {
            _ = try await service.fetchVehicleRentals(in: seattleBoundingBox, formFactors: nil)
            XCTFail("Expected fetchVehicleRentals to throw")
        } catch let error as OTPKitError {
            guard case .apiError(let message, _) = error else {
                return XCTFail("Expected apiError, got \(error)")
            }
            XCTAssertTrue(message.contains("Validation error"))
        }
    }

    func testFetchVehicleRentalsSkipsUnknownTypename() async throws {
        let json = """
        {"data":{"vehicleRentalsByBbox":[
            {"__typename":"RentalDrone","droneId":"x"},
            {"__typename":"RentalVehicle","vehicleId":"lime_seattle:abc","name":"Default vehicle type",
             "lat":47.61,"lon":-122.33,"allowPickupNow":true,"operative":true,
             "rentalNetwork":null,"rentalUris":null,"vehicleType":null,"fuel":null}
        ]}}
        """
        mockDataLoader.mockResponse(data: Data(json.utf8))

        let result = try await service.fetchVehicleRentals(in: seattleBoundingBox, formFactors: nil)

        // A union member OTP adds later degrades to a skipped entry — it must never
        // abort the decode of the thousands of entities around it.
        XCTAssertEqual(result.rentals.map(\.id), ["lime_seattle:abc"])
    }

    func testFetchVehicleRentalsThrowsOnHTTPError() async throws {
        mockDataLoader.mockResponse(data: Data("{}".utf8), statusCode: 502)

        do {
            _ = try await service.fetchVehicleRentals(in: seattleBoundingBox, formFactors: nil)
            XCTFail("Expected fetchVehicleRentals to throw")
        } catch let error as OTPKitError {
            guard case .apiError(_, let statusCode) = error else {
                return XCTFail("Expected apiError, got \(error)")
            }
            XCTAssertEqual(statusCode, 502)
        }
    }

    // MARK: - Error Handling

    func testFetchPlanMapsRoutingErrors() async throws {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_plan_routing_error.json"))

        let response = try await service.fetchPlan(createTripPlanRequest())

        XCTAssertEqual(response.plan?.itineraries.count, 0)
        let error = try XCTUnwrap(response.error)
        XCTAssertEqual(error.messageCode, .outsideBounds)
        XCTAssertTrue(error.message.contains("outside the map data boundary"))
        // GraphQL routing errors carry no wire id; it must stay absent, not a fabricated sentinel.
        XCTAssertNil(error.id)
    }

    func testFetchPlanMapsUnrecognizedRoutingErrorToUnknown() async throws {
        let json = """
        {"data":{"plan":{
            "date":1785340800000,
            "from":{"name":"Origin","lon":-80.0,"lat":25.0,"vertexType":"NORMAL"},
            "to":{"name":"Destination","lon":-122.3493,"lat":47.6205,"vertexType":"NORMAL"},
            "routingErrors":[{"code":"SOME_FUTURE_CODE","description":"Something new went wrong."}],
            "itineraries":[]
        }}}
        """
        mockDataLoader.mockResponse(data: Data(json.utf8))

        let response = try await service.fetchPlan(createTripPlanRequest())

        let error = try XCTUnwrap(response.error)
        XCTAssertEqual(error.messageCode, .unknown)
        XCTAssertEqual(error.message, "Something new went wrong.")
        XCTAssertNil(error.id)
    }

    func testFetchPlanThrowsOnTopLevelGraphQLError() async throws {
        let errorJSON = """
        {"errors":[{"message":"Validation error (FieldUndefined@[plan]) : Field 'plan' is undefined"}]}
        """
        mockDataLoader.mockResponse(data: Data(errorJSON.utf8))

        do {
            _ = try await service.fetchPlan(createTripPlanRequest())
            XCTFail("Expected fetchPlan to throw")
        } catch let error as OTPKitError {
            guard case .apiError(let message, _) = error else {
                return XCTFail("Expected apiError, got \(error)")
            }
            XCTAssertTrue(message.contains("Validation error"))
        }
    }

    func testFetchPlanThrowsOnHTTPError() async throws {
        mockDataLoader.mockResponse(data: Data("{}".utf8), statusCode: 500)

        do {
            _ = try await service.fetchPlan(createTripPlanRequest())
            XCTFail("Expected fetchPlan to throw")
        } catch let error as OTPKitError {
            guard case .apiError(_, let statusCode) = error else {
                return XCTFail("Expected apiError, got \(error)")
            }
            XCTAssertEqual(statusCode, 500)
        }
    }
}

// MARK: - Test Helpers

private extension GraphQLAPIServiceTests {
    static let testDate = DateFormatter.tripDateFormatter.date(from: "05-10-2024")!
    static let testTime = DateFormatter.tripAPITimeFormatter.date(from: "08:00")!

    var seattleBoundingBox: VehicleRentalBoundingBox {
        VehicleRentalBoundingBox(
            minimumLatitude: 47.5,
            maximumLatitude: 47.7,
            minimumLongitude: -122.4,
            maximumLongitude: -122.2
        )
    }

    func createTripPlanRequest(transportModes: [TransportMode] = [.transit, .walk]) -> TripPlanRequest {
        TestFixtures.makeTripPlanRequest(
            origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
            destination: CLLocationCoordinate2D(latitude: 47.6205, longitude: -122.3493),
            date: Self.testDate,
            time: Self.testTime,
            transportModes: transportModes,
            maxWalkDistance: 800
        )
    }

    /// Mocks the captured live-server success fixture and fetches a plan through the service.
    func fetchSuccessPlan() async throws -> OTPResponse {
        mockDataLoader.mockResponse(data: Fixtures.loadData(file: "graphql_plan_success.json"))
        return try await service.fetchPlan(createTripPlanRequest())
    }
}
