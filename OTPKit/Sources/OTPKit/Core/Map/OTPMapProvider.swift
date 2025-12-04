//
//  OTPMapProvider.swift
//  OTPKit
//
//  Created by OTPKit on 2025-09-02.
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

/// Protocol defining the interface for map operations that OTPKit requires.
/// Implementers of this protocol can provide their own map view (MKMapView, custom map, etc.)
/// while allowing OTPKit to control map content and interactions.
public protocol OTPMapProvider: AnyObject {

    // MARK: - Route Display

    /// Adds a route polyline to the map with specified styling
    /// - Parameters:
    ///   - coordinates: Array of coordinates forming the route
    ///   - color: Color for the route line
    ///   - lineWidth: Width of the route line
    ///   - identifier: Unique identifier for this route segment
    ///   - lineDashPattern: Optional dash pattern for the line (e.g., [0, 8] for dotted line)
    func addRoute(
        coordinates: [CLLocationCoordinate2D],
        color: Color,
        lineWidth: CGFloat,
        identifier: String,
        lineDashPattern: [NSNumber]?
    )

    /// Removes a specific route from the map
    /// - Parameter identifier: Identifier of the route to remove
    func removeRoute(identifier: String)

    /// Removes all routes from the map
    func clearAllRoutes()

    // MARK: - Annotations

    /// Adds an annotation (marker) to the map
    /// - Parameters:
    ///   - coordinate: Location for the annotation
    ///   - title: Title for the annotation
    ///   - subtitle: Optional subtitle
    ///   - identifier: Unique identifier for this annotation
    ///   - type: Type of annotation (origin, destination, station, etc.)
    ///   - routeName: Optional route name for route legend annotations
    ///   - routeBackgroundColor: Optional background color for route legend badge
    ///   - routeTextColor: Optional text color for route legend badge
    func addAnnotation(
        coordinate: CLLocationCoordinate2D,
        title: String,
        subtitle: String?,
        identifier: String,
        type: OTPAnnotationType,
        routeName: String?,
        routeBackgroundColor: UIColor?,
        routeTextColor: UIColor?
    )

    /// Removes a specific annotation from the map
    /// - Parameter identifier: Identifier of the annotation to remove
    func removeAnnotation(identifier: String)

    /// Removes all annotations from the map
    func clearAllAnnotations()

    // MARK: - Camera Control

    /// Sets the map camera to show a specific region
    /// - Parameters:
    ///   - region: The region to display
    ///   - animated: Whether to animate the camera movement
    func setRegion(_ region: MKCoordinateRegion, animated: Bool)

    /// Sets the map camera to fit a bounding rectangle
    /// - Parameters:
    ///   - mapRect: The rectangle to fit in view
    ///   - edgePadding: Padding around the rectangle
    ///   - animated: Whether to animate the camera movement
    func setVisibleMapRect(
        _ mapRect: MKMapRect,
        edgePadding: UIEdgeInsets,
        animated: Bool
    )

    /// Gets the current visible region of the map
    /// - Returns: The current map region
    func getCurrentRegion() -> MKCoordinateRegion

    // MARK: - User Interaction

    /// Registers a handler for tap gestures on the map
    /// - Parameter handler: Closure called when user taps on the map
    func onMapTap(_ handler: @escaping (CLLocationCoordinate2D) -> Void)

    /// Registers a handler for annotation selection
    /// - Parameter handler: Closure called when user selects an annotation
    func onAnnotationSelected(_ handler: @escaping (String) -> Void)

    // MARK: - User Location

    /// Shows or hides the user's current location on the map
    /// - Parameter show: Whether to show the user location
    func showUserLocation(_ show: Bool)

    /// Centers the map on the user's current location
    /// - Parameter animated: Whether to animate the camera movement
    func centerOnUserLocation(animated: Bool)

    // MARK: - Map Configuration

    /// Sets the map type (standard, satellite, hybrid, etc.)
    /// - Parameter mapType: The map type to display
    func setMapType(_ mapType: MKMapType)

    /// Enables or disables user interaction with the map
    /// - Parameter enabled: Whether interaction is enabled
    func setUserInteractionEnabled(_ enabled: Bool)

    /// Shows or hides map controls (compass, scale, etc.)
    /// - Parameter visible: Whether controls are visible
    func setControlsVisible(_ visible: Bool)
}

/// Types of annotations that can be displayed on the map
public enum OTPAnnotationType {
    case origin
    case destination
    case transitStop
    case transitStation
    case waypoint
    case currentLocation
    case searchResult
    case routeLegend
    case embark
    case debark
    case intermediateStop

    /// Returns the appropriate color for this annotation type
    public var color: Color {
        switch self {
        case .origin:
            return .green
        case .destination:
            return .red
        case .transitStop, .transitStation:
            return .blue
        case .waypoint:
            return .orange
        case .currentLocation:
            return .blue
        case .searchResult:
            return .gray
        case .embark:
            return .blue
        case .debark:
            return .orange
        case .intermediateStop:
            return .gray
        case .routeLegend:
            return .clear // Custom view will handle coloring
        }
    }

    /// Returns the appropriate system image name for this annotation type
    public var systemImageName: String {
        switch self {
        case .origin:
            return "location.circle.fill"
        case .destination:
            return "mappin.circle.fill"
        case .transitStop:
            return "bus.fill"
        case .transitStation:
            return "tram.fill"
        case .embark:
            return "arrow.up.circle.fill"
        case .debark:
            return "arrow.down.circle.fill"
        case .waypoint:
            return "flag.fill"
        case .currentLocation:
            return "location.fill"
        case .searchResult:
            return "magnifyingglass"
        case .intermediateStop:
            return "circle.fill"
        case .routeLegend:
            return "" // Custom view will handle display
        }
    }
}

/// Extension to provide default implementations for optional methods
public extension OTPMapProvider {
    func setControlsVisible(_ visible: Bool) {
        // Default implementation - can be overridden
    }

    func setMapType(_ mapType: MKMapType) {
        // Default implementation - can be overridden
    }
}
