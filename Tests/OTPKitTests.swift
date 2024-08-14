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

// swiftlint:disable force_cast line_length

@testable import OTPKit
import XCTest

class OTPKitTests: OTPTestCase {
    let soundTransitBaseURL = URL(string: "https://otp.prod.sound.obaweb.org/otp/routers/default/")!

    func testPlanBasics() async throws {
        let restApi = buildRestAPIClient()

        let dataLoader = restApi.dataLoader as! MockDataLoader

        dataLoader.mock(URLString: "https://otp.prod.sound.obaweb.org/otp/routers/default/plan?fromPlace=47.6097,-122.3331&toPlace=47.6154,-122.3208&time=8:00%20AM&date=05-10-2024&mode=TRANSIT,WALK&arriveBy=false&maxWalkDistance=800&wheelchair=false", with: Fixtures.loadData(file: "plan_basic_case.json"))

        let result = try await restApi.fetchPlan(
            fromPlace: "47.6097,-122.3331",
            toPlace: "47.6154,-122.3208",
            time: "8:00 AM",
            date: "05-10-2024",
            mode: "TRANSIT,WALK",
            arriveBy: false,
            maxWalkDistance: 800,
            wheelchair: false
        )

        XCTAssertNotNil(result)

        let plan = result.plan!

        XCTAssertNotNil(plan)

        XCTAssertEqual(plan.itineraries.count, 3)

        let itinerary = plan.itineraries.first

        XCTAssertEqual(itinerary?.duration, 595)
    }
}

// swiftlint:enable force_cast line_length
