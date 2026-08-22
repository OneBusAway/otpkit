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
import SwiftUI
import ViewInspector
@testable import OTPKit

/// Covers the embedded-chrome integration path: a host that supplies its own
/// navigation gets no close button from OTPKit, so `TripPlanner.reset()` is the
/// only way it can return the planner to a clean state.
@Suite("TripPlanner embedded chrome")
@MainActor
struct TripPlannerChromeTests {

    private func makePlanner(
        mapProvider: MockMapProvider,
        apiService: TestFixtures.MockAPIService = TestFixtures.MockAPIService()
    ) -> TripPlanner {
        TripPlanner(
            otpConfig: TestFixtures.makeOTPConfiguration(),
            apiService: apiService,
            mapProvider: mapProvider,
            notificationCenter: NotificationCenter()
        )
    }

    /// Puts a real trip on the planner: origin and destination annotations on the
    /// map, and an itinerary in the view model. Without this, assertions about
    /// clearing pass vacuously — `MapCoordinator.clearLocations()` removes both
    /// annotation identifiers whether or not anything was ever drawn.
    private func planTrip(on planner: TripPlanner) async {
        let viewModel = planner.viewModel
        viewModel.handleLocationSelection(TestHelpers.location(title: "Origin"), for: .origin)
        viewModel.handleLocationSelection(TestHelpers.location(title: "Destination"), for: .destination)
        viewModel.planTrip()
        await viewModel.activePlanTask?.value
    }

    // MARK: - Framing

    @Test("standalone wraps the planner in its own navigation chrome")
    func standaloneSuppliesNavigationChrome() throws {
        let planner = makePlanner(mapProvider: MockMapProvider())
        let view = TripPlannerView(
            viewModel: planner.viewModel,
            mapCoordinator: planner.mapCoordinator,
            chrome: .standalone
        ) {}

        let body = try view.inspect()
        #expect(throws: Never.self) { try body.find(ViewType.NavigationStack.self) }
    }

    @Test("embedded renders the body alone, leaving navigation to the host")
    func embeddedOmitsNavigationChrome() throws {
        let planner = makePlanner(mapProvider: MockMapProvider())
        let view = TripPlannerView(
            viewModel: planner.viewModel,
            mapCoordinator: planner.mapCoordinator,
            chrome: .embedded
        )

        let body = try view.inspect()
        // The distinguishing property of `.embedded`: no container of OTPKit's own,
        // so the host's navigation title and toolbar survive.
        #expect(throws: (any Error).self) { try body.find(ViewType.NavigationStack.self) }
        // The body itself is still there — `.embedded` drops the chrome, not the planner.
        #expect(throws: Never.self) { try body.find(ViewType.ScrollView.self) }
    }

    // MARK: - Prefill

    @Test("Rebuilding the view in either chrome mode preserves a planned trip")
    func chromeModesPreservePlannedTrip() async throws {
        let mapProvider = MockMapProvider()
        let planner = makePlanner(mapProvider: mapProvider)
        await planTrip(on: planner)

        let routesClearedWhilePlanning = mapProvider.clearAllRoutesCalls

        _ = planner.createTripPlannerView(chrome: .standalone) {}
        _ = planner.createTripPlannerView(chrome: .embedded)

        // Chrome only decides how the body is framed. A SwiftUI host rebuilds its
        // views freely, so neither the rider's selections nor the map may be
        // disturbed by doing so.
        #expect(planner.viewModel.selectedOrigin != nil)
        #expect(planner.viewModel.selectedDestination != nil)
        #expect(mapProvider.clearAllRoutesCalls == routesClearedWhilePlanning)
        #expect(mapProvider.removeAnnotationCalls.isEmpty)
    }

    @Test("Chrome defaults to standalone, preserving existing integrations")
    func chromeDefaultsToStandalone() throws {
        let planner = makePlanner(mapProvider: MockMapProvider())

        // The pre-existing call shape: no `chrome`, close handler as a trailing
        // closure. It must still compile and still produce standalone chrome.
        let view = planner.createTripPlannerView {}

        #expect(throws: Never.self) { try view.inspect().find(ViewType.NavigationStack.self) }
    }

    // MARK: - reset()

    @Test("reset() clears the trip an embedded host cannot close out of")
    func resetClearsPlannedTrip() async throws {
        let mapProvider = MockMapProvider()
        let planner = makePlanner(mapProvider: mapProvider)
        await planTrip(on: planner)

        _ = planner.createTripPlannerView(chrome: .embedded)

        // Precondition: there is genuinely something to clear.
        #expect(planner.viewModel.selectedOrigin != nil)
        #expect(planner.viewModel.selectedDestination != nil)
        #expect(planner.viewModel.tripPlanResponse != nil)
        #expect(mapProvider.addAnnotationCalls.contains { $0.identifier == "origin" })
        #expect(mapProvider.addAnnotationCalls.contains { $0.identifier == "destination" })

        planner.reset()

        // View model state is the assertion that bites: the map provider removes
        // both annotation identifiers unconditionally, so map calls alone would
        // pass even if `reset()` did nothing.
        #expect(planner.viewModel.selectedOrigin == nil)
        #expect(planner.viewModel.selectedDestination == nil)
        #expect(planner.viewModel.viaPoint == nil)
        #expect(planner.viewModel.tripPlanResponse == nil)
        #expect(planner.viewModel.selectedItinerary == nil)
        #expect(mapProvider.clearAllRoutesCalls > 0)
        #expect(mapProvider.removeAnnotationCalls.contains("origin"))
        #expect(mapProvider.removeAnnotationCalls.contains("destination"))
    }

    @Test("reset() clears a via point set through the factory")
    func resetClearsViaPoint() throws {
        let planner = makePlanner(mapProvider: MockMapProvider())

        _ = planner.createTripPlannerView(
            viaPoint: CLLocationCoordinate2D(latitude: 47.6, longitude: -122.3),
            transportMode: .transit,
            chrome: .embedded
        )
        #expect(planner.viewModel.viaPoint != nil)

        planner.reset()

        #expect(planner.viewModel.viaPoint == nil)
    }
}
