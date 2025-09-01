//
//  TripPlannerViewModel.swift
//  OTPKit
//
//  Created by Manu on 2025-07-05.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

/// Main view model for handling trip planning functionality
/// Manages location selection, transport modes, API calls, and UI state
class TripPlannerViewModel: SheetPresenter, ObservableObject {

    // MARK: - Published Properties

    /// Currently active sheet being presented
    @Published var activeSheet: Sheet?

    /// Selected origin location for the trip
    @Published var selectedOrigin: Location?

    /// Selected destination location for the trip
    @Published var selectedDestination: Location?

    /// Currently selected transport mode (transit, walk, bike, car)
    @Published var selectedTransportMode: TransportMode = .transit

    /// User-selected departure time
    @Published var departureTime: Date?

    /// User-selected departure date
    @Published var departureDate: Date?

    // MARK: - Advanced Options

    /// Whether the route should be wheelchair accessible
    @Published var isWheelchairAccessible: Bool = false

    /// Maximum walking distance preference
    @Published var maxWalkingDistance: WalkingDistance = .oneMile

    /// Time preference (leave now, depart at, arrive by)
    @Published var timePreference: TimePreference = .leaveNow

    /// Route optimization preference
    @Published var routePreference: RoutePreference = .fastestTrip

    /// Loading state for API calls
    @Published var isLoading = false

    /// Response from the OTP API containing trip plans
    @Published var triPlanResponse: OTPResponse?

    /// Error message to display to user
    @Published var errorMessage: String?

    /// Whether to show the trip results sheet
    @Published var showingTripResults = false

    /// Whether to show error alert
    @Published var showingError = false

    /// Currently previewed itinerary for map display
    @Published var selectedItinerary: Itinerary?

    /// Whether to show the route polyline on map
    @Published var showingPolyline = false

    /// Current map camera position/region
    @Published var region: MapCameraPosition = .userLocation(fallback: .automatic)

    // MARK: - Configuration

    /// OTP configuration containing server URL and enabled transport modes
    private let config: OTPConfiguration

    /// API service for making trip planning requests
    private let apiService: APIService

    /// Initialize with OTP configuration and API service
    init(config: OTPConfiguration, apiService: APIService) {
        self.config = config
        self.apiService = apiService
        self.region = config.region
        // Set the first enabled transport mode as default, fallback to transit
        self.selectedTransportMode = config.enabledTransportModes.first ?? .transit
    }

    /// Sets the current location as the origin for trip planning
    @MainActor
    func setCurrentLocationAsOrigin() async {
        if let currentLocation = await LocationManager.shared.getCurrentLocation() {
            selectedOrigin = currentLocation
            changeMapCamera(to: currentLocation.coordinate)
        }
    }

    // MARK: - Computed Properties

    /// Returns true if both origin and destination are selected
    var canPlanTrip: Bool {
        selectedOrigin != nil && selectedDestination != nil
    }

    /// Available transport modes from configuration
    var enabledTransportModes: [TransportMode] {
        config.enabledTransportModes
    }

    /// All available itineraries from the current trip plan response
    var itineraries: [Itinerary] {
        triPlanResponse?.plan?.itineraries ?? []
    }

    // MARK: - Transport & Time Management

    /// Update the selected transport mode
    /// - Parameter mode: The transport mode to select
    func selectTransportMode(_ mode: TransportMode) {
        selectedTransportMode = mode
    }

    /// Update the departure time for the trip
    /// - Parameter time: The selected departure time
    func updateDepartureTime(_ time: Date) {
        departureTime = time
    }

    // MARK: - Trip Planning

    /// Plan a trip using the current origin, destination,
    /// Plans a trip using the current origin, destination, and transport mode settings.
    /// Makes an API call to the OTP server and updates the UI state accordingly.
    @MainActor
    func planTrip() {
        // Validate that we have required locations
        guard let origin = selectedOrigin, let destination = selectedDestination else {
            showError(OTPKitError.missingOriginOrDestination)
            return
        }

        // Determine date and time based on time preference
        let (requestDate, requestTime) = getRequestDateTime()

        // Create trip plan request
        let request = TripPlanRequest(
            origin: origin.coordinate,
            destination: destination.coordinate,
            date: requestDate,
            time: requestTime,
            transportModes: selectedTransportMode.apiModes,
            maxWalkDistance: maxWalkingDistance.meters,
            wheelchairAccessible: isWheelchairAccessible,
            arriveBy: timePreference == .arriveBy
        )

        // Start loading state
        isLoading = true
        errorMessage = nil
        showingError = false

        Task {
            do {
                let response = try await apiService.fetchPlan(request)
                await MainActor.run {
                    self.handleSuccess(response)
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }

    // MARK: - Private Helpers

    /// Determines the appropriate date and time for the trip request based on time preference
    /// - Returns: A tuple containing the date and time to use for the request
    private func getRequestDateTime() -> (Date, Date) {
        switch timePreference {
        case .leaveNow:
            // Use current date and time
            let now = Date()
            return (now, now)
        case .departAt, .arriveBy:
            // Use stored departure date and time, fallback to current if nil
            let requestDate = departureDate ?? Date()
            let requestTime = departureTime ?? Date()
            return (requestDate, requestTime)
        }
    }

    private func handleSuccess(_ response: OTPResponse) {
        triPlanResponse = response
        isLoading = false
        showingTripResults = true
        showTripResultsSheet()
        HapticManager.shared.success()
    }

    private func handleError(_ error: Error) {
        let otpError = error as? OTPKitError ?? OTPKitError.tripPlanningFailed(error.localizedDescription)
        showError(otpError)
    }

    private func showError(_ error: OTPKitError) {
        errorMessage = error.displayMessage
        showingError = true
        isLoading = false
    }

    // MARK: - Sheet Presentation

    /// Present the location options sheet
    func showLocationOptions() {
        present(.library)
    }

    /// Present the trip results sheet
    func showTripResultsSheet() {
        present(.tripResults)
    }

    // MARK: - Preview Management

    /// Clear the current route preview from the map
    func clearPreview() {
        selectedItinerary = nil
        showingPolyline = false
    }

    /// Show route preview on the map for a specific itinerary
    /// - Parameter itinerary: The itinerary to preview
    private func showPreview(for itinerary: Itinerary) {
        selectedItinerary = itinerary
        showingPolyline = true
        // Zoom to fit the entire trip with padding
        zoomToFitItinerary(itinerary)
    }

    // MARK: - Action Handlers

    /// Handle location selection from various UI components
    /// Updates the appropriate location (origin/destination) and moves map camera
    /// - Parameters:
    ///   - location: The selected location
    ///   - mode: Whether this is for origin or destination
    func handleLocationSelection(_ location: Location, for mode: LocationMode) {
        // Use location coordinate helper for map camera
        changeMapCamera(to: location.coordinate)

        // Update the appropriate location based on mode
        switch mode {
        case .origin:
            selectedOrigin = location
        case .destination:
            selectedDestination = location
        }

        // Dismiss the current sheet
        dismiss()
    }

    /// Handle itinerary selection (user wants to use this route)
    /// Shows preview on map, dismisses current sheet, and opens route details
    /// - Parameter itinerary: The selected itinerary
    func handleItinerarySelection(_ itinerary: Itinerary) {
        selectedItinerary = itinerary
        showingPolyline = true
        // Zoom to origin for turn-by-turn directions like Apple Maps
        if let origin = selectedOrigin {
            changeMapCamera(
                to: origin.coordinate,
                latMeters: 1800,
                longMeters: 1800
            )
        }
        dismiss()
        present(.directions)
    }

    /// Handle itinerary preview (user wants to see route on map)
    /// Shows preview on map and dismisses current sheet
    /// - Parameter itinerary: The itinerary to preview
    func handleItineraryPreview(_ itinerary: Itinerary) {
        showPreview(for: itinerary)
        dismiss()
    }

    // MARK: - Reset Functionality

    /// Reset all trip planner state to initial values
    /// Clears locations, itineraries, and returns to clean state
    func resetTripPlanner() {
        // Clear location selections
        selectedOrigin = nil
        selectedDestination = nil

        // Clear trip planning results
        triPlanResponse = nil
        selectedItinerary = nil

        // Reset map state
        showingPolyline = false
//        region = .userLocation(fallback: .automatic)

        // Clear error states
        errorMessage = nil
        showingError = false
        isLoading = false

        // Reset to default transport mode
        selectedTransportMode = config.enabledTransportModes.first ?? .transit

        // Reset advanced options to defaults
        isWheelchairAccessible = false
        maxWalkingDistance = .oneMile
        timePreference = .leaveNow
        routePreference = .fastestTrip
        departureTime = nil
        departureDate = nil

        // Dismiss any active sheets
        activeSheet = nil
    }
}

// MARK: - Map Management
extension TripPlannerViewModel {
    /// Update map camera to focus on specific coordinate
    /// - Parameters:
    ///   - coordinate: The coordinate to center the map on
    ///   - latMeters: Latitudinal meters for zoom level
    ///   - longMeters: Longitudinal meters for zoom level
    func changeMapCamera(
        to coordinate: CLLocationCoordinate2D,
        latMeters: Double = 1000,
        longMeters: Double = 1000
    ) {
        let pos = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: latMeters,
            longitudinalMeters: longMeters
        )

        withAnimation(.easeInOut(duration: 0.8)) {
            region = .region(pos)
        }
    }

    /// Zoom camera to fit entire itinerary using native Apple MapKit API
    /// - Parameter itinerary: The itinerary to fit in view
    func zoomToFitItinerary(_ itinerary: Itinerary) {
        var coordinates: [CLLocationCoordinate2D] = []

        // Add origin if available
        if let origin = selectedOrigin { coordinates.append(origin.coordinate) }

        // Add all coordinates from legs
        for leg in itinerary.legs {
            if let legCoordinates = leg.decodePolyline(), !legCoordinates.isEmpty {
                coordinates.append(contentsOf: legCoordinates)
            }
        }

        // Add destination if available
        if let destination = selectedDestination { coordinates.append(destination.coordinate) }

        guard !coordinates.isEmpty else { return }

        // Handle single coordinate case
        if coordinates.count == 1 {
            changeMapCamera(to: coordinates[0])
            return
        }

        // Use Apple's native MKPolyline to get the bounding map rect
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        let mapRect = polyline.boundingMapRect

        // Convert MKMapRect to MKCoordinateRegion with native Apple padding
        let region = MKCoordinateRegion(mapRect)

        // Apply native Apple-style padding by expanding the region slightly
        let paddedRegion = MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: region.span.latitudeDelta * 1.15,
                longitudeDelta: region.span.longitudeDelta * 1.15
            )
        )

        withAnimation(.easeInOut(duration: 1.0)) {
            self.region = .region(paddedRegion)
        }
    }
}
