//
//  DirectionSheetViewModel.swift
//  OTPKit
//
//  Created by Manu on 2025-06-06.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

/// ViewModel for DirectionSheetView
/// Handles direction display, map camera control, and scroll management
@Observable
final class DirectionSheetViewModel: BaseViewModel {

    // MARK: - Dependencies
    private let tripPlannerService: TripPlannerService

    // MARK: - Published Properties

    /// Current selected itinerary
    var selectedItinerary: Itinerary? {
        tripPlannerService.selectedItinerary
    }

    /// Origin coordinate
    var originCoordinate: CLLocationCoordinate2D? {
        tripPlannerService.originCoordinate
    }

    /// Destination coordinate
    var destinationCoordinate: CLLocationCoordinate2D? {
        tripPlannerService.destinationCoordinate
    }

    /// Origin name for display
    var originName: String {
        tripPlannerService.originName
    }

    /// Destination name for display
    var destinationName: String {
        tripPlannerService.destinationName
    }

    /// Page title
    var pageTitle: String {
        destinationName
    }

    // MARK: - Initialization

    init(tripPlannerService: TripPlannerService) {
        self.tripPlannerService = tripPlannerService
        super.init()
    }

    // MARK: - Public Methods

    /// Resets trip planner and dismisses directions
    public func resetTripPlanner() {
        tripPlannerService.resetTripPlanner()
    }

    /// Handles tap on coordinate and updates map camera
    public func handleCoordinateTap(_ coordinate: CLLocationCoordinate2D) {
        tripPlannerService.changeMapCamera(to: coordinate)
    }

    /// Handles tap on origin location
    public func handleOriginTap() {
        guard let originCoordinate = originCoordinate else { return }
        handleCoordinateTap(originCoordinate)
    }

    /// Handles tap on destination location
    public func handleDestinationTap() {
        guard let destinationCoordinate = destinationCoordinate else { return }
        handleCoordinateTap(destinationCoordinate)
    }

    /// Handles tap on leg destination
    public func handleLegTap(_ leg: Leg) {
        let coordinate = CLLocationCoordinate2D(latitude: leg.to.lat, longitude: leg.to.lon)
        handleCoordinateTap(coordinate)
    }

    /// Generates appropriate leg view type based on transportation mode
    public func getLegViewType(for leg: Leg) -> DirectionLegViewType {
        switch leg.mode {
        case "BUS", "TRAM":
            return .vehicle
        case "WALK":
            return .walk
        default:
            return .unknown
        }
    }

    /// Generates unique ID for scroll targeting
    public func generateItemId(for index: Int) -> String {
        "item-\(index)"
    }

    /// Generates origin item ID
    public var originItemId: String {
        generateItemId(for: 0)
    }

    /// Generates destination item ID for given itinerary
    public func destinationItemId(for itinerary: Itinerary) -> String {
        generateItemId(for: itinerary.legs.count + 1)
    }

    /// Gets total number of items (origin + legs + destination)
    public func getTotalItemCount(for itinerary: Itinerary) -> Int {
        itinerary.legs.count + 2 // origin + legs + destination
    }
}

// MARK: - Supporting Types

/// Enum to determine which direction leg view to display
public enum DirectionLegViewType {
    case vehicle
    case walk
    case unknown
}
