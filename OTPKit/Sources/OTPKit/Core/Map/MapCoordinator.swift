//
//  MapCoordinator.swift
//  OTPKit
//
//  Created by OTPKit on 2025-09-02.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI
import OSLog

/// Coordinates all map operations between OTPKit and the external map provider
/// This class manages routes, annotations, and user interactions with the map
@MainActor
public class MapCoordinator: ObservableObject {

    let originIdentifier = "origin"
    let destinationIdentifier = "destination"

    // MARK: - Properties

    private let mapProvider: OTPMapProvider
    private let locationManager = LocationManager.shared

    /// Currently displayed itinerary on the map
    @Published public var displayedItinerary: Itinerary?

    /// Whether a route is currently being displayed
    @Published public var isShowingRoute: Bool = false

    /// Current map region
    @Published public var currentRegion: MKCoordinateRegion?

    // MARK: - Constants

    private enum Constants {
        static let routeLineWidth: CGFloat = 4.0
        static let routeHaloWidth: CGFloat = 6.0
        static let mapPadding: CGFloat = 50.0
    }

    // MARK: - Initialization

    /// Creates a new map coordinator with the provided map provider
    /// - Parameter mapProvider: The map provider to coordinate
    public init(mapProvider: OTPMapProvider) {
        self.mapProvider = mapProvider
        setupMapInteractions()
    }

    private func setupMapInteractions() {
        // Set up tap handler for location selection
        mapProvider.onMapTap { [weak self] coordinate in
            self?.handleMapTap(at: coordinate)
        }

        // Set up annotation selection handler
        mapProvider.onAnnotationSelected { [weak self] identifier in
            self?.handleAnnotationSelected(identifier: identifier)
        }
    }

    // MARK: - Route Display

    /// Displays an itinerary route on the map
    /// - Parameter itinerary: The itinerary to display
    public func showItinerary(_ itinerary: Itinerary) {
        clearRoute()

        displayedItinerary = itinerary
        isShowingRoute = true

        // Add route segments for each leg
        for (index, leg) in itinerary.legs.enumerated() {
            if let coordinates = leg.decodePolyline(), !coordinates.isEmpty {
                let legColor = colorForTransportMode(leg.mode)
                let dashPattern = dashPatternForTransportMode(leg.mode)

                // Add white halo for better visibility
                mapProvider.addRoute(
                    coordinates: coordinates,
                    color: .white.opacity(0.8),
                    lineWidth: Constants.routeHaloWidth,
                    identifier: "halo_leg_\(index)",
                    lineDashPattern: dashPattern
                )

                // Add colored route
                mapProvider.addRoute(
                    coordinates: coordinates,
                    color: legColor,
                    lineWidth: Constants.routeLineWidth,
                    identifier: "leg_\(index)",
                    lineDashPattern: dashPattern
                )

                // Add mode icon at midpoint
                addTransportModeAnnotation(for: leg, index: index, coordinates: coordinates)

                // Add station annotations
                addStationAnnotations(for: leg, index: index, totalLegs: itinerary.legs.count)
            }
        }

        // Fit all routes in view
        fitRoutesInView(itinerary: itinerary)
    }

    /// Clears the currently displayed route from the map
    public func clearRoute() {
        mapProvider.clearAllRoutes()
        mapProvider.clearAllAnnotations()
        displayedItinerary = nil
        isShowingRoute = false
    }

    // MARK: - Location Management

    /// Sets an origin location on the map
    /// - Parameter location: The origin location
    public func setOrigin(_ location: Location) {
        mapProvider.addAnnotation(
            coordinate: location.coordinate,
            title: location.title,
            subtitle: location.subTitle,
            identifier: originIdentifier,
            type: .origin
        )
    }

    /// Sets a destination location on the map
    /// - Parameter location: The destination location
    public func setDestination(_ location: Location) {
        mapProvider.addAnnotation(
            coordinate: location.coordinate,
            title: location.title,
            subtitle: location.subTitle,
            identifier: destinationIdentifier,
            type: .destination
        )
    }

    /// Clears origin and destination from the map
    public func clearLocations() {
        mapProvider.removeAnnotation(identifier: originIdentifier)
        mapProvider.removeAnnotation(identifier: destinationIdentifier)
    }

    // MARK: - Camera Control

    /// Centers the map on a specific coordinate
    /// - Parameters:
    ///   - coordinate: The coordinate to center on
    ///   - animated: Whether to animate the movement
    public func centerOn(coordinate: CLLocationCoordinate2D, animated: Bool = true) {
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapProvider.setRegion(region, animated: animated)
    }

    /// Centers the map on the user's current location
    /// - Parameter animated: Whether to animate the movement
    public func centerOnUserLocation(animated: Bool = true) {
        mapProvider.centerOnUserLocation(animated: animated)
    }

    // MARK: - User Location

    /// Shows or hides the user location on the map
    /// - Parameter show: Whether to show the user location
    public func showUserLocation(_ show: Bool) {
        mapProvider.showUserLocation(show)
    }

    // MARK: - Private Methods

    private func colorForTransportMode(_ mode: String) -> Color {
        switch mode.uppercased() {
        case "WALK":
            return .gray
        case "BUS", "TRAM", "TRAIN", "SUBWAY", "FERRY":
            return .blue
        case "BIKE", "CAR":
            return .orange
        default:
            return .gray
        }
    }

    private func dashPatternForTransportMode(_ mode: String) -> [NSNumber]? {
        switch mode.uppercased() {
        case "WALK":
            // Apple Maps style dotted line for walking
            return [3, 10]
        default:
            // Solid line for all other transport modes
            return nil
        }
    }

    private func iconForTransportMode(_ mode: String) -> String {
        switch mode.uppercased() {
        case "WALK":
            return "figure.walk"
        case "BUS":
            return "bus"
        case "TRAM":
            return "tram"
        case "BIKE":
            return "bicycle"
        case "CAR":
            return "car"
        case "TRAIN", "SUBWAY":
            return "train.side.front.car"
        case "FERRY":
            return "ferry"
        default:
            return "questionmark"
        }
    }

    private func addTransportModeAnnotation(for leg: Leg, index: Int, coordinates: [CLLocationCoordinate2D]) {
//        let midIndex = coordinates.count / 2
//        let position = coordinates[midIndex]

        // For now, we'll skip mode annotations as they require custom rendering
        // This can be enhanced later with custom annotation views
    }

    private func addStationAnnotations(for leg: Leg, index: Int, totalLegs: Int) {
        // Add station annotation for "from" location if it's a transit stop
        if shouldShowStation(for: leg.from) {
            mapProvider.addAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: leg.from.lat, longitude: leg.from.lon),
                title: leg.from.name,
                subtitle: nil,
                identifier: "station_from_\(index)",
                type: .transitStop
            )
        }

        // Add "to" location only for the last leg
        if index == totalLegs - 1 && shouldShowStation(for: leg.to) {
            mapProvider.addAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: leg.to.lat, longitude: leg.to.lon),
                title: leg.to.name,
                subtitle: nil,
                identifier: "station_to_\(index)",
                type: .transitStop
            )
        }
    }

    private func shouldShowStation(for place: Place) -> Bool {
        return place.vertexType == "STOP" ||
               place.vertexType == "STATION" ||
               place.stopId != nil
    }

    private func fitRoutesInView(itinerary: Itinerary) {
        Logger.main.debug("fitRoutesInView: Attempting to fit \(itinerary.legs.count) legs")

        guard let mapRect = itinerary.boundingBox else {
            Logger.main.warning("fitRoutesInView: No bounding box available")
            return
        }

        Logger.main.debug("fitRoutesInView: Setting visible rect - (\(mapRect.origin.x), \(mapRect.origin.y)), size: (\(mapRect.size.width), \(mapRect.size.height))")

        let padding = UIEdgeInsets(
            top: Constants.mapPadding,
            left: Constants.mapPadding,
            bottom: Constants.mapPadding,
            right: Constants.mapPadding
        )

        mapProvider.setVisibleMapRect(mapRect, edgePadding: padding, animated: true)
    }

    // MARK: - Event Handlers

    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        // This will be connected to the view model for location selection
        // For now, we'll just update the current region
        currentRegion = mapProvider.getCurrentRegion()
    }

    private func handleAnnotationSelected(identifier: String) {
        // Handle annotation selection if needed
        Logger.main.info("Annotation selected: \(identifier)")
    }
}
