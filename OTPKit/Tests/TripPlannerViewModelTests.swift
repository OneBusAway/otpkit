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
import Foundation
import CoreLocation
@testable import OTPKit

@Suite("TripPlannerViewModel Comprehensive Tests")
@MainActor
struct TripPlannerViewModelTests {

    // MARK: - Test Helpers

    func createViewModel(
        enabledModes: [TransportMode] = [.transit, .walk, .bike],
        mockAPIService: TestFixtures.MockAPIService? = nil
    ) -> TripPlannerViewModel {
        // Clear UserDefaults before each test to ensure clean state
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "OTPKit.TripOptions.wheelchairAccessible")
        defaults.removeObject(forKey: "OTPKit.TripOptions.maxWalkingDistance")
        defaults.removeObject(forKey: "OTPKit.TripOptions.routePreference")

        let config = TestFixtures.makeOTPConfiguration(enabledModes: enabledModes)

        let apiService = mockAPIService ?? TestFixtures.MockAPIService()
        let mapProvider = MockMapProvider()
        let mapCoordinator = MapCoordinator(mapProvider: mapProvider)

        return TripPlannerViewModel(
            config: config,
            apiService: apiService,
            mapCoordinator: mapCoordinator
        )
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with correct defaults")
    func initializesWithCorrectDefaults() {
        let viewModel = createViewModel()

        #expect(viewModel.activeSheet == nil)
        #expect(viewModel.selectedOrigin == nil)
        #expect(viewModel.selectedDestination == nil)
        #expect(viewModel.selectedTransportMode == .transit)
        #expect(viewModel.departureTime == nil)
        #expect(viewModel.departureDate == nil)
        #expect(viewModel.isWheelchairAccessible == false)
        #expect(viewModel.maxWalkingDistance == .oneMile)
        #expect(viewModel.timePreference == .leaveNow)
        #expect(viewModel.routePreference == .fastestTrip)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.tripPlanResponse == nil)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingError == false)
        #expect(viewModel.selectedItinerary == nil)
    }

    @Test("ViewModel uses first enabled transport mode from config")
    func usesFirstEnabledTransportMode() {
        let viewModel = createViewModel(enabledModes: [.bike, .transit])

        #expect(viewModel.selectedTransportMode == .bike)
    }

    @Test("ViewModel falls back to transit if no modes enabled")
    func fallsBackToTransitIfNoModesEnabled() {
        let viewModel = createViewModel(enabledModes: [])

        #expect(viewModel.selectedTransportMode == .transit)
    }

    // MARK: - Computed Properties Tests

    @Test("canPlanTrip returns false when origin is nil")
    func canPlanTripWithoutOrigin() {
        let viewModel = createViewModel()
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")

        #expect(viewModel.canPlanTrip == false)
    }

    @Test("canPlanTrip returns false when destination is nil")
    func canPlanTripWithoutDestination() {
        let viewModel = createViewModel()
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")

        #expect(viewModel.canPlanTrip == false)
    }

    @Test("canPlanTrip returns true when both locations are set")
    func canPlanTripWithBothLocations() {
        let viewModel = createViewModel()
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")

        #expect(viewModel.canPlanTrip == true)
    }

    @Test("enabledTransportModes returns config modes")
    func enabledTransportModesReturnsConfigModes() {
        let viewModel = createViewModel(enabledModes: [.bike, .car])

        #expect(viewModel.enabledTransportModes == [.bike, .car])
    }

    @Test("itineraries returns empty array when no response")
    func itinerariesEmptyWhenNoResponse() {
        let viewModel = createViewModel()

        #expect(viewModel.itineraries.isEmpty)
    }

    // MARK: - Transport Mode Selection Tests

    @Test("selectTransportMode updates selected mode")
    func selectTransportModeUpdatesMode() {
        let viewModel = createViewModel()

        viewModel.selectTransportMode(.bike)

        #expect(viewModel.selectedTransportMode == .bike)
    }

    // MARK: - Time Management Tests

    @Test("updateDepartureTime sets departure time")
    func updateDepartureTimeSetsTime() {
        let viewModel = createViewModel()
        let testDate = Date()

        viewModel.updateDepartureTime(testDate)

        #expect(viewModel.departureTime == testDate)
    }

    // MARK: - planTrip Tests

    @Test("planTrip fails when origin is missing")
    func planTripFailsWhenOriginMissing() async throws {
        let viewModel = createViewModel()
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")

        viewModel.planTrip()

        // Allow async operations to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        #expect(viewModel.showingError == true)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("planTrip fails when destination is missing")
    func planTripFailsWhenDestinationMissing() async throws {
        let viewModel = createViewModel()
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")

        viewModel.planTrip()

        // Allow async operations to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        #expect(viewModel.showingError == true)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("planTrip succeeds with valid locations")
    func planTripSucceedsWithValidLocations() async throws {
        let mockAPIService = TestFixtures.MockAPIService()
        let mockResponse = TestHelpers.response(with: [])
        mockAPIService.mockResponse = mockResponse

        let viewModel = createViewModel(mockAPIService: mockAPIService)
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")

        viewModel.planTrip()

        // Allow async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        #expect(viewModel.isLoading == false)
        #expect(viewModel.tripPlanResponse != nil)
        #expect(viewModel.showingError == false)
        #expect(mockAPIService.fetchPlanCallCount == 1)
    }

    @Test("planTrip sets loading state correctly")
    func planTripSetsLoadingState() async throws {
        let mockAPIService = TestFixtures.MockAPIService()
        mockAPIService.mockResponse = TestHelpers.response(with: [])

        let viewModel = createViewModel(mockAPIService: mockAPIService)
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")

        viewModel.planTrip()

        // Check that loading state was set
        // Note: isLoading may already be false by the time we check due to async completion

        // Allow async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        #expect(viewModel.isLoading == false)
    }

    @Test("planTrip handles API errors")
    func planTripHandlesAPIErrors() async throws {
        let mockAPIService = TestFixtures.MockAPIService()
        mockAPIService.shouldThrowError = true
        mockAPIService.mockError = OTPKitError.apiError("Network error")

        let viewModel = createViewModel(mockAPIService: mockAPIService)
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")

        viewModel.planTrip()

        // Allow async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        #expect(viewModel.showingError == true)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("planTrip clears previous errors")
    func planTripClearsPreviousErrors() async throws {
        let mockAPIService = TestFixtures.MockAPIService()
        mockAPIService.mockResponse = TestHelpers.response(with: [])

        let viewModel = createViewModel(mockAPIService: mockAPIService)
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")

        // Set existing error state
        viewModel.errorMessage = "Previous error"
        viewModel.showingError = true

        viewModel.planTrip()

        // Allow async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        #expect(viewModel.showingError == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("planTrip uses wheelchair accessible setting")
    func planTripUsesWheelchairSetting() async throws {
        let mockAPIService = TestFixtures.MockAPIService()
        mockAPIService.mockResponse = TestHelpers.response(with: [])

        let viewModel = createViewModel(mockAPIService: mockAPIService)
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")
        viewModel.isWheelchairAccessible = true

        viewModel.planTrip()

        // Allow async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        #expect(mockAPIService.lastRequest?.wheelchairAccessible == true)
    }

    @Test("planTrip uses maxWalkDistance setting")
    func planTripUsesMaxWalkDistance() async throws {
        let mockAPIService = TestFixtures.MockAPIService()
        mockAPIService.mockResponse = TestHelpers.response(with: [])

        let viewModel = createViewModel(mockAPIService: mockAPIService)
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")
        viewModel.maxWalkingDistance = .halfMile

        viewModel.planTrip()

        // Allow async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        #expect(mockAPIService.lastRequest?.maxWalkDistance == WalkingDistance.halfMile.meters)
    }

    @Test("planTrip uses arriveBy when timePreference is arriveBy")
    func planTripUsesArriveBy() async throws {
        let mockAPIService = TestFixtures.MockAPIService()
        mockAPIService.mockResponse = TestHelpers.response(with: [])

        let viewModel = createViewModel(mockAPIService: mockAPIService)
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")
        viewModel.timePreference = .arriveBy

        viewModel.planTrip()

        // Allow async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        #expect(mockAPIService.lastRequest?.arriveBy == true)
    }

    @Test("planTrip uses leaveNow time preference")
    func planTripUsesLeaveNowTimePreference() async throws {
        let mockAPIService = TestFixtures.MockAPIService()
        mockAPIService.mockResponse = TestHelpers.response(with: [])

        let viewModel = createViewModel(mockAPIService: mockAPIService)
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")
        viewModel.timePreference = .leaveNow

        viewModel.planTrip()

        // Allow async operations to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        #expect(mockAPIService.lastRequest?.arriveBy == false)
    }

    // MARK: - Sheet Presentation Tests

    @Test("presentSheet sets active sheet")
    func presentSheetSetsActiveSheet() {
        let viewModel = createViewModel()
        let location = TestHelpers.location()
        let itinerary = TestHelpers.itinerary()
        let trip = Trip(origin: location, destination: location, itinerary: itinerary)

        viewModel.presentSheet(.directions(trip))

        #expect(viewModel.activeSheet != nil)
    }

    @Test("dismissSheet clears active sheet")
    func dismissSheetClearsActiveSheet() {
        let viewModel = createViewModel()
        let location = TestHelpers.location()
        let itinerary = TestHelpers.itinerary()
        let trip = Trip(origin: location, destination: location, itinerary: itinerary)

        viewModel.presentSheet(.directions(trip))
        viewModel.dismissSheet()

        #expect(viewModel.activeSheet == nil)
    }

    // MARK: - Location Selection Tests

    @Test("handleLocationSelection sets origin")
    func handleLocationSelectionSetsOrigin() {
        let viewModel = createViewModel()
        let location = TestHelpers.location(title: "Test Origin")

        viewModel.handleLocationSelection(location, for: .origin)

        #expect(viewModel.selectedOrigin?.title == "Test Origin")
        #expect(viewModel.activeSheet == nil) // Should dismiss sheet
    }

    @Test("handleLocationSelection sets destination")
    func handleLocationSelectionSetsDestination() {
        let viewModel = createViewModel()
        let location = TestHelpers.location(title: "Test Destination")

        viewModel.handleLocationSelection(location, for: .destination)

        #expect(viewModel.selectedDestination?.title == "Test Destination")
        #expect(viewModel.activeSheet == nil) // Should dismiss sheet
    }

    // MARK: - Itinerary Handling Tests

    @Test("clearPreview clears selected itinerary")
    func clearPreviewClearsItinerary() {
        let viewModel = createViewModel()
        viewModel.selectedItinerary = TestHelpers.itinerary()

        viewModel.clearPreview()

        #expect(viewModel.selectedItinerary == nil)
    }

    @Test("handleTripStarted sets selected itinerary")
    func handleTripStartedSetsItinerary() {
        let viewModel = createViewModel()
        let origin = TestHelpers.location(title: "Origin")
        let destination = TestHelpers.location(title: "Destination")
        viewModel.selectedOrigin = origin
        viewModel.selectedDestination = destination

        let itinerary = TestHelpers.itinerary()
        viewModel.handleTripStarted(itinerary)

        #expect(viewModel.selectedItinerary != nil)
    }

    @Test("handleTripStarted opens directions sheet")
    func handleTripStartedOpensDirectionsSheet() {
        let viewModel = createViewModel()
        let origin = TestHelpers.location(title: "Origin")
        let destination = TestHelpers.location(title: "Destination")
        viewModel.selectedOrigin = origin
        viewModel.selectedDestination = destination

        let itinerary = TestHelpers.itinerary()
        viewModel.handleTripStarted(itinerary)

        #expect(viewModel.activeSheet != nil)
    }

    @Test("handleItineraryPreview opens preview sheet")
    func handleItineraryPreviewOpensSheet() {
        let viewModel = createViewModel()
        let origin = TestHelpers.location(title: "Origin")
        let destination = TestHelpers.location(title: "Destination")
        viewModel.selectedOrigin = origin
        viewModel.selectedDestination = destination

        let itinerary = TestHelpers.itinerary()
        viewModel.handleItineraryPreview(itinerary)

        #expect(viewModel.activeSheet != nil)
    }

    // MARK: - Reset Tests

    @Test("resetTripPlanner clears all state")
    func resetTripPlannerClearsAllState() {
        let viewModel = createViewModel()

        // Set up some state (trip-specific, not persisted preferences)
        viewModel.selectedOrigin = TestHelpers.location(title: "Origin")
        viewModel.selectedDestination = TestHelpers.location(title: "Destination")
        viewModel.tripPlanResponse = TestHelpers.response(with: [])
        viewModel.selectedItinerary = TestHelpers.itinerary()
        viewModel.errorMessage = "Test error"
        viewModel.showingError = true
        viewModel.isLoading = true
        viewModel.selectedTransportMode = .bike
        viewModel.timePreference = .arriveBy
        viewModel.departureTime = Date()
        viewModel.departureDate = Date()
        // Note: Not modifying isWheelchairAccessible/maxWalkingDistance/routePreference
        // as these are persisted to UserDefaults asynchronously, which would create
        // a race condition with resetTripPlanner()'s reload from UserDefaults

        // Clear UserDefaults again right before reset to avoid race conditions
        // with async saves from other tests
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "OTPKit.TripOptions.wheelchairAccessible")
        defaults.removeObject(forKey: "OTPKit.TripOptions.maxWalkingDistance")
        defaults.removeObject(forKey: "OTPKit.TripOptions.routePreference")

        // Reset
        viewModel.resetTripPlanner()

        // Verify everything is reset
        #expect(viewModel.selectedOrigin == nil)
        #expect(viewModel.selectedDestination == nil)
        #expect(viewModel.tripPlanResponse == nil)
        #expect(viewModel.selectedItinerary == nil)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingError == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.selectedTransportMode == .transit)
        #expect(viewModel.isWheelchairAccessible == false)
        #expect(viewModel.maxWalkingDistance == .oneMile)
        #expect(viewModel.timePreference == .leaveNow)
        #expect(viewModel.routePreference == .fastestTrip)
        #expect(viewModel.departureTime == nil)
        #expect(viewModel.departureDate == nil)
        #expect(viewModel.activeSheet == nil)
    }
}
