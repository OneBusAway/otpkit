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
    @Published var previewItinerary: Itinerary?

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

    // MARK: - Location Management

    /// Update map camera to focus on specific coordinate
    /// - Parameter coordinate: The coordinate to center the map on
    func changeMapCamera(to coordinate: CLLocationCoordinate2D) {
        let pos = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000, 
            longitudinalMeters: 1000
        )
        region = .region(pos)
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
    /// Makes API call to OTP server and updates UI state accordingly
    @MainActor
    func planTrip() {
        // Validate that we have required locations
        guard let origin = selectedOrigin, let destination = selectedDestination else {
            showError(OTPKitError.missingOriginOrDestination)
            return
        }

        // Create trip plan request
        let request = TripPlanRequest(
            origin: origin.coordinate,
            destination: destination.coordinate,
            date: departureDate ?? Date(),
            time: departureTime ?? Date(),
            transportModes: selectedTransportMode.apiModes,
            maxWalkDistance: 1000,
            wheelchairAccessible: false,
            arriveBy: false
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
    private func handleSuccess(_ response: OTPResponse) {
        triPlanResponse = response
        isLoading = false
        showingTripResults = true
        showTripResultsSheet()
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
        present(.locationOptions)
    }

    /// Present the trip results sheet
    func showTripResultsSheet() {
        present(.tripResults)
    }

    /// Present the route details sheet
    func showRouteDetails() {
        present(.routeDetails)
    }

    /// Present the settings sheet
    func showSettings() {
        present(.settings)
    }

    // MARK: - Preview Management

    /// Clear the current route preview from the map
    func clearPreview() {
        previewItinerary = nil
        showingPolyline = false
    }

    /// Show route preview on the map for a specific itinerary
    /// - Parameter itinerary: The itinerary to preview
    private func showPreview(for itinerary: Itinerary) {
        previewItinerary = itinerary
        showingPolyline = true
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
        showPreview(for: itinerary)
        dismiss()
        present(.routeDetails)
    }

    /// Handle itinerary preview (user wants to see route on map)
    /// Shows preview on map and dismisses current sheet
    /// - Parameter itinerary: The itinerary to preview
    func handleItineraryPreview(_ itinerary: Itinerary) {
        showPreview(for: itinerary)
        dismiss()
    }
}
