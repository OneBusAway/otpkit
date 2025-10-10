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

class RestAPIServiceTests: OTPTestCase {

    private var restAPIService: RestAPIService!
    private var mockDataLoader: MockDataLoader!

    override func setUp() {
        super.setUp()
        restAPIService = buildRestAPIService()
        mockDataLoader = (restAPIService.dataLoader as? MockDataLoader)!
    }

    /// Some regions in the OBA regions directory ("https://regions.onebusaway.org/regions-v3.json") are missing
    /// some required parts of their URL path. I don't understand why, exactly. It seems to be a behavior carried over from older
    /// versions of OTP, and then never corrected in the regions directory. {shrug}
    ///
    /// In any case, by default the OBA Android app munges "routers/default" onto its URLs when making requests to the OTP server.
    /// If it gets a 500 error back from the server, it removes the munged "routers/default" from subsequent API calls. Yuck.
    func testSDMTSURLMunging() {
        let sdmtsService = buildRestAPIService(baseURLString: "https://realtime.sdmts.com:9091/otp")
        let urlString = sdmtsService.buildURL(endpoint: "plan").absoluteString
        XCTAssertEqual(urlString, "https://realtime.sdmts.com:9091/otp/routers/default/plan")
    }

    func testFetchPlanWithTripPlanRequest() async throws {
        // Arrange
        let request = createTripPlanRequest(transportModes: [.transit, .walk], maxWalkDistance: 800)
        let expectedURL = createExpectedURL(for: request)

        mockDataLoader.mock(URLString: expectedURL, with: Fixtures.loadData(file: "plan_basic_case.json"))

        // Act
        let result = try await restAPIService.fetchPlan(request)

        // Assert
        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result.plan, "Plan should not be nil")
        XCTAssertEqual(result.plan?.itineraries.count, 3, "Should return 3 itineraries")
    }

    func testFetchPlanWithDifferentTransportModes() async throws {
        // Arrange
        let request = createTripPlanRequest(transportModes: [.bike, .walk], maxWalkDistance: 1000)
        let expectedURL = createExpectedURL(for: request)

        mockDataLoader.mock(URLString: expectedURL, with: Fixtures.loadData(file: "plan_basic_case.json"))

        // Act
        let result = try await restAPIService.fetchPlan(request)

        // Assert
        XCTAssertNotNil(result, "Response should not be nil")
        XCTAssertNotNil(result.plan, "Plan should not be nil")
    }
}

// MARK: - Test Helpers
private extension RestAPIServiceTests {
   func createTripPlanRequest(
       transportModes: [TransportMode] = [.transit, .walk],
       maxWalkDistance: Int = 800,
       wheelchairAccessible: Bool = false,
       arriveBy: Bool = false
   ) -> TripPlanRequest {
       guard let date = DateFormatter.tripDateFormatter.date(from: "05-10-2024"),
             let time = DateFormatter.tripAPITimeFormatter.date(from: "08:00") else {
           XCTFail("Failed to parse test dates")
           fatalError("Test setup failure")
       }

       return TripPlanRequest(
           origin: CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3331),
           destination: CLLocationCoordinate2D(latitude: 47.6154, longitude: -122.3208),
           date: date,
           time: time,
           transportModes: transportModes,
           maxWalkDistance: maxWalkDistance,
           wheelchairAccessible: wheelchairAccessible,
           arriveBy: arriveBy
       )
   }

   func createExpectedURL(for request: TripPlanRequest) -> String {
       let baseURL = "https://otp.prod.sound.obaweb.org/otp/routers/default/plan"
       let fromPlace = request.origin.formattedForAPI
       let toPlace = request.destination.formattedForAPI
       let time = request.time.formattedTripTime
       let date = request.date.formattedTripDate
       let mode = request.transportModesString
       let arriveBy = request.arriveBy ? "true" : "false"
       let maxWalkDistance = String(request.maxWalkDistance)
       let wheelchair = request.wheelchairAccessible ? "true" : "false"

       // swiftlint:disable:next line_length
       let retVal = "\(baseURL)?fromPlace=\(fromPlace)&toPlace=\(toPlace)&time=\(time)&date=\(date)&mode=\(mode)&arriveBy=\(arriveBy)&maxWalkDistance=\(maxWalkDistance)&wheelchair=\(wheelchair)"

       return retVal
   }
}
