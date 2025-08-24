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

final class TripPlannerViewModelTests: XCTestCase {
    private var viewModel: TripPlannerViewModel!
    private var mockConfig: OTPConfiguration!
    private var mockAPIService: MockAPIService!

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
            enabledTransportModes: [.transit, .walk, .bike],
            region: .userLocation(fallback: .automatic)
        )
        mockAPIService = MockAPIService()
        viewModel = TripPlannerViewModel(config: mockConfig, apiService: mockAPIService)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockConfig = nil
        mockAPIService = nil
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
            (viewModel.triPlanResponse as Any?, "triPlanResponse"),
            (viewModel.errorMessage as Any?, "errorMessage"),
            (viewModel.selectedItinerary as Any?, "previewItinerary")
        ] {
            XCTAssertNil(value, "\(name) should be nil initially")
        }

        // Bools start false
        for (value, name) in [
            (viewModel.isLoading, "isLoading"),
            (viewModel.showingTripResults, "showingTripResults"),
            (viewModel.showingError, "showingError"),
            (viewModel.showingPolyline, "showingPolyline")
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
            enabledTransportModes: [],
            region: .userLocation(fallback: .automatic)
        )
        let mockAPIService = MockAPIService()
        let vm = TripPlannerViewModel(config: cfg, apiService: mockAPIService)
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
        viewModel.triPlanResponse = nil
        XCTAssertTrue(viewModel.itineraries.isEmpty)
    }

    /// Itineraries mirror those in the response plan
    func test_Itineraries_returnsPlanItineraries() {
        let itin = TestHelpers.itinerary()
        viewModel.triPlanResponse = TestHelpers.response(with: [itin])
        XCTAssertEqual(viewModel.itineraries.count, 1)
        XCTAssertEqual(viewModel.itineraries.first?.duration, itin.duration)
    }

    // MARK: - Sheets

    /// Each sheet presenter should set the expected `activeSheet`
    func test_ShowSheets_setsActiveSheet() {
        viewModel.showLocationOptions()
        XCTAssertEqual(viewModel.activeSheet, .locationOptions)

        viewModel.showTripResultsSheet()
        XCTAssertEqual(viewModel.activeSheet, .tripResults)

        viewModel.present(.directions)
        XCTAssertEqual(viewModel.activeSheet, .directions)

        viewModel.present(.search)
        XCTAssertEqual(viewModel.activeSheet, .search)
    }

    // MARK: - Preview & Actions

    /// Clearing preview should reset both `previewItinerary` and `showingPolyline`
    func test_ClearPreview_resetsState() {
        let itin = TestHelpers.itinerary()
        viewModel.handleItineraryPreview(itin) // sets preview + polyline + dismiss
        XCTAssertNotNil(viewModel.selectedItinerary)
        XCTAssertTrue(viewModel.showingPolyline)

        viewModel.clearPreview()
        XCTAssertNil(viewModel.selectedItinerary)
        XCTAssertFalse(viewModel.showingPolyline)
    }

    /// Previewing an itinerary sets preview + polyline and dismisses any sheet
    func test_HandleItineraryPreview_setsPreviewAndDismisses() {
        viewModel.activeSheet = .tripResults
        let itin = TestHelpers.itinerary()

        viewModel.handleItineraryPreview(itin)

        XCTAssertEqual(viewModel.selectedItinerary, itin)
        XCTAssertTrue(viewModel.showingPolyline)
        XCTAssertNil(viewModel.activeSheet) // dismissed
    }

    /// Selecting an itinerary sets preview + polyline and presents route details
    func test_HandleItinerarySelection_setsPreviewAndPresentsRouteDetails() {
        viewModel.activeSheet = .tripResults
        let itin = TestHelpers.itinerary()

        viewModel.handleItinerarySelection(itin)

        XCTAssertEqual(viewModel.selectedItinerary, itin)
        XCTAssertTrue(viewModel.showingPolyline)
        XCTAssertEqual(viewModel.activeSheet, .directions)
    }

    // MARK: - Map Camera

    /// Changing map camera should update the `region` backing enum
    func test_ChangeMapCamera_updatesRegionCase() {
        let before = String(describing: viewModel.region)
        viewModel.changeMapCamera(to: CLLocationCoordinate2D(latitude: 47.0, longitude: -122.0))
        let after = String(describing: viewModel.region)
        XCTAssertNotEqual(before, after)
    }
}
