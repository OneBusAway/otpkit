//
//  TripPlannerSheetViewModel.swift
//  OTPKit
//
//  Created by Manu on 2025-06-06.
//

import Foundation
import SwiftUI

/// ViewModel for TripPlannerSheetView
/// Handles itinerary selection and trip planning logic
@Observable
final class TripPlannerSheetViewModel: BaseViewModel {

    // MARK: - Dependencies
    private let tripPlannerService: TripPlannerService

    // MARK: - Published Properties

    /// Available itineraries from the plan response
    var availableItineraries: [Itinerary] {
        tripPlannerService.planResponse?.plan?.itineraries ?? []
    }

    /// Whether there are itineraries to display
    var hasItineraries: Bool {
        !availableItineraries.isEmpty
    }

    /// Error message when no trip planner data is available
    var noTripPlannerMessage: String {
        "Can't find trip planner. Please try another pin point"
    }

    // MARK: - Initialization

    init(tripPlannerService: TripPlannerService) {
        self.tripPlannerService = tripPlannerService
        super.init()
    }

    // MARK: - Public Methods

    /// Selects an itinerary and dismisses the sheet
    func selectItinerary(_ itinerary: Itinerary) {
        tripPlannerService.selectedItinerary = itinerary
        tripPlannerService.planResponse = nil
    }

    /// Selects an itinerary, adjusts camera, and dismisses sheet
    func previewItinerary(_ itinerary: Itinerary) {
        tripPlannerService.selectedItinerary = itinerary
        tripPlannerService.planResponse = nil
        tripPlannerService.adjustOriginDestinationCamera()
    }

    /// Cancels trip planning and resets all data
    func cancelTripPlanning() {
        tripPlannerService.resetTripPlanner()
    }

    /// Generates appropriate leg view type based on transportation mode
    func getLegViewType(for leg: Leg) -> TripLegViewType {
        switch leg.mode {
        case "BUS", "TRAM":
            return .vehicle
        case "WALK":
            return .walk
        default:
            return .unknown
        }
    }

    /// Formats itinerary start time for display
    func formatStartTime(_ itinerary: Itinerary) -> String {
        "Bus scheduled at \(Formatters.formatDateToTime(itinerary.startTime))"
    }

    /// Formats itinerary duration for display
    func formatDuration(_ itinerary: Itinerary) -> String {
        Formatters.formatTimeDuration(itinerary.duration)
    }
}

// MARK: - Supporting Types

/// Enum to determine which leg view to display
enum TripLegViewType {
    case vehicle
    case walk
    case unknown
}
