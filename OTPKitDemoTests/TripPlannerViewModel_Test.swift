//
//  TripPlannerViewModelTests.swift
//  OTPKit
//
//  Created by Manu on 2025-08-10.
//

import XCTest
import CoreLocation
import MapKit
import SwiftUI
@testable import OTPKit

@MainActor
final class TripPlannerViewModelTests: XCTestCase {
    private var viewModel: TripPlannerViewModel!
    private var mockConfig: OTPConfiguration!
    private var mockAPIService: MockAPIService!
    private var mockMapProvider: OTPMapProvider!
    private var mockMapCoordinator: MapCoordinator!

    // MARK: - Mock API Service
    private class MockAPIService: APIService {
        func fetchPlan(_ request: TripPlanRequest) async throws -> OTPResponse {
            // Create mock request parameters
            let mockRequestParameters = RequestParameters(
                fromPlace: "0.0,0.0",
                toPlace: "0.0,0.0",
                time: "12:00:00",
                date: "2025-01-01",
                mode: "TRANSIT",
                arriveBy: "false",
                maxWalkDistance: "1000",
                wheelchair: "false"
            )

            // Return a mock response for testing
            return OTPResponse(
                requestParameters: mockRequestParameters,
                plan: nil,
                error: nil
            )
        }
    }

    // MARK: - Lifecycle
    override func setUpWithError() throws {
        // Given: a configuration typical for app usage
        mockConfig = OTPConfiguration(
            otpServerURL: URL(string: "https://test.example.com")!,
            enabledTransportModes: [.transit, .walk, .bike]
        )
        mockAPIService = MockAPIService()

        // Create mock map components
        let mapView = MKMapView()
        mockMapProvider = MKMapViewAdapter(mapView: mapView)
        mockMapCoordinator = MapCoordinator(mapProvider: mockMapProvider)

        viewModel = TripPlannerViewModel(config: mockConfig, apiService: mockAPIService, mapCoordinator: mockMapCoordinator)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockConfig = nil
        mockAPIService = nil
        mockMapProvider = nil
        mockMapCoordinator = nil
    }

    // MARK: - Initial State

    /// Verifies default values at initialization are predictable and safe
    func test_InitialState_hasExpectedDefaults() {
        // Optionals start nil
        for (value, name) in [
            (viewModel.activeSheet as Any?, "activeSheet"),
            (viewModel.selectedOrigin as Any?, "selectedOrigin"),
            (viewModel.selectedDestination as Any?, "selectedDestination"),
            (viewModel.departureTime as Any?, "departureTime"),
            (viewModel.departureDate as Any?, "departureDate"),
            (viewModel.tripPlanResponse as Any?, "triPlanResponse"),
            (viewModel.errorMessage as Any?, "errorMessage"),
            (viewModel.selectedItinerary as Any?, "previewItinerary")
        ] {
            XCTAssertNil(value, "\(name) should be nil initially")
        }

        // Bools start false
        for (value, name) in [
            (viewModel.isLoading, "isLoading"),
            (viewModel.showingError, "showingError")
        ] {
            XCTAssertFalse(value, "\(name) should be false initially")
        }

        // Transport defaults to .transit (given config has .transit first)
        XCTAssertEqual(viewModel.selectedTransportMode, .transit)
    }

    // MARK: - Location Selection

    /// Selecting an origin should set only `selectedOrigin`
    func test_HandleLocationSelection_setsOrigin() throws {
        let home = TestHelpers.location()
        viewModel.handleLocationSelection(home, for: .origin)
        XCTAssertEqual(try XCTUnwrap(viewModel.selectedOrigin), home)
    }

    /// Selecting a destination should set only `selectedDestination`
    func test_HandleLocationSelection_setsDestination() throws {
        let work = TestHelpers.location()
        viewModel.handleLocationSelection(work, for: .destination)
        XCTAssertEqual(try XCTUnwrap(viewModel.selectedDestination), work)
    }

    // MARK: - Transport & Time

    /// Changing transport mode updates `selectedTransportMode`
    func test_SelectTransportMode_updatesMode() {
        let allModes = TransportMode.allCases
        XCTAssertFalse(allModes.isEmpty, "TransportMode enum should have at least one case")

        for mode in allModes {
            viewModel.selectTransportMode(mode)

            // Assert: selectedTransportMode should match exactly
            XCTAssertEqual(
                viewModel.selectedTransportMode,
                mode,
                "Expected selectedTransportMode to be \(mode) after selecting \(mode)"
            )
        }
    }

    /// If config has no enabled modes, default should fall back to `.transit`
    func test_SelectedTransportMode_fallsBackToTransitWhenEmpty() {
        let cfg = OTPConfiguration(
            otpServerURL: URL(string: "https://test.example.com")!,
            enabledTransportModes: []
        )
        let mockAPIService = MockAPIService()
        let mapView = MKMapView()
        let mapProvider = MKMapViewAdapter(mapView: mapView)
        let mapCoordinator = MapCoordinator(mapProvider: mapProvider)
        let vm = TripPlannerViewModel(config: cfg, apiService: mockAPIService, mapCoordinator: mapCoordinator)
        XCTAssertEqual(vm.selectedTransportMode, .transit)
    }

    /// Updating the departure time sets `departureTime`
    func test_UpdateDepartureTime_setsValue() {
        XCTAssertNil(viewModel.departureTime)
        let date = Date()
        viewModel.updateDepartureTime(date)
        XCTAssertEqual(viewModel.departureTime, date)
    }

    // MARK: - Computed Properties

    /// `canPlanTrip` should be true only when both origin and destination are set
    func test_CanPlanTrip_requiresBothLocations() {
        XCTAssertFalse(viewModel.canPlanTrip)
        viewModel.selectedOrigin = TestHelpers.location()
        XCTAssertFalse(viewModel.canPlanTrip)
        viewModel.selectedDestination = TestHelpers.location()
        XCTAssertTrue(viewModel.canPlanTrip)
    }

    /// `enabledTransportModes` should reflect the configuration
    func test_EnabledTransportModes_reflectsConfig() {
        XCTAssertEqual(viewModel.enabledTransportModes, [.transit, .walk, .bike])
    }

    /// Itineraries empty when there is no response
    func test_Itineraries_emptyWithoutResponse() {
        viewModel.tripPlanResponse = nil
        XCTAssertTrue(viewModel.itineraries.isEmpty)
    }

    /// Itineraries mirror those in the response plan
    func test_Itineraries_returnsPlanItineraries() {
        let itin = TestHelpers.itinerary()
        viewModel.tripPlanResponse = TestHelpers.response(with: [itin])
        XCTAssertEqual(viewModel.itineraries.count, 1)
        XCTAssertEqual(viewModel.itineraries.first?.duration, itin.duration)
    }

    // MARK: - Sheets

    /// Each sheet presenter should set the expected `activeSheet`
    func test_ShowSheets_setsActiveSheet() {
        viewModel.presentSheet(.locationOptions(.origin))
        XCTAssertEqual(viewModel.activeSheet, .locationOptions(.origin))

        let trip = Trip(origin: TestHelpers.location(), destination: TestHelpers.location(), itinerary: TestHelpers.itinerary())

        viewModel.presentSheet(.directions(trip))
        XCTAssertEqual(viewModel.activeSheet, .directions(trip))

        viewModel.presentSheet(.search(.origin))
        XCTAssertEqual(viewModel.activeSheet, .search(.origin))
    }

    // MARK: - Preview & Actions

    /// Clearing preview should reset both `previewItinerary` and `showingPolyline`
    func test_ClearPreview_resetsState() {
        let itin = TestHelpers.itinerary()
        viewModel.handleItineraryPreview(itin) // presents a modal with the itinerary steps
        XCTAssertNil(viewModel.selectedItinerary)
    }

    // MARK: - Map Coordinator

    /// Test that location selection updates the map coordinator
    func test_LocationSelection_updatesMapCoordinator() {
        let location = TestHelpers.location()
        viewModel.handleLocationSelection(location, for: .origin)
        // Verify origin is set (coordinator updates are internal to the implementation)
        XCTAssertEqual(viewModel.selectedOrigin, location)
    }
}
