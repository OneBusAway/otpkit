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

import Testing
import CoreLocation
import Foundation
@testable import OTPKit

/// Covers the embedded-chrome integration path: a host that supplies its own
/// navigation gets no close button from OTPKit, so `TripPlanner.reset()` is the
/// only way it can return the planner to a clean state.
@Suite("TripPlanner embedded chrome")
@MainActor
struct TripPlannerChromeTests {

    private func makePlanner(
        mapProvider: MockMapProvider
    ) -> TripPlanner {
        TripPlanner(
            otpConfig: TestFixtures.makeOTPConfiguration(),
            apiService: TestFixtures.MockAPIService(),
            mapProvider: mapProvider,
            notificationCenter: NotificationCenter()
        )
    }

    @Test("Both chrome modes build a view without touching planner state")
    func chromeModesBuildIndependently() {
        let mapProvider = MockMapProvider()
        let planner = makePlanner(mapProvider: mapProvider)

        _ = planner.createTripPlannerView(chrome: .standalone) {}
        _ = planner.createTripPlannerView(chrome: .embedded) {}

        // Chrome only decides how the body is framed. Choosing it must not clear a
        // trip or redraw the map, because a host may rebuild the view repeatedly.
        #expect(mapProvider.clearAllRoutesCalls == 0)
        #expect(mapProvider.clearAllAnnotationsCalls == 0)
    }

    @Test("Chrome defaults to standalone, preserving existing integrations")
    func chromeDefaultsToStandalone() {
        let mapProvider = MockMapProvider()
        let planner = makePlanner(mapProvider: mapProvider)

        // Compiles only while `chrome` has a default, which is what keeps the
        // parameter additive for callers that predate it.
        _ = planner.createTripPlannerView {}

        #expect(mapProvider.clearAllRoutesCalls == 0)
    }

    @Test("reset() clears the route an embedded host cannot close out of")
    func resetClearsMapState() {
        let mapProvider = MockMapProvider()
        let planner = makePlanner(mapProvider: mapProvider)

        _ = planner.createTripPlannerView(
            viaPoint: CLLocationCoordinate2D(latitude: 47.6, longitude: -122.3),
            transportMode: .transit,
            chrome: .embedded
        ) {}

        planner.reset()

        // `resetTripPlanner()` routes through the map coordinator, so a cleared
        // route and cleared locations are the observable proof it ran.
        #expect(mapProvider.clearAllRoutesCalls > 0)
        #expect(mapProvider.removeAnnotationCalls.contains("origin"))
        #expect(mapProvider.removeAnnotationCalls.contains("destination"))
    }
}
