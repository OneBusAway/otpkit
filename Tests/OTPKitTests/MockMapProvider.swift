//
//  MockMapProvider.swift
//  OTPKitTests
//
//  Mock implementation of OTPMapProvider for testing
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI
@testable import OTPKit

/// Mock implementation of OTPMapProvider for testing
/// Tracks all method calls and state for verification in tests
class MockMapProvider: OTPMapProvider {

    // MARK: - Call Tracking

    var addRouteCalls: [(coordinates: [CLLocationCoordinate2D], color: Color, lineWidth: CGFloat, identifier: String, lineDashPattern: [NSNumber]?)] = []
    var removeRouteCalls: [String] = []
    var clearAllRoutesCalls: Int = 0

    var addAnnotationCalls: [(coordinate: CLLocationCoordinate2D, title: String, subtitle: String?, identifier: String, type: OTPAnnotationType, routeName: String?, routeBackgroundColor: UIColor?, routeTextColor: UIColor?)] = []
    var removeAnnotationCalls: [String] = []
    var clearAllAnnotationsCalls: Int = 0

    var setRegionCalls: [(region: MKCoordinateRegion, animated: Bool)] = []
    var setVisibleMapRectCalls: [(mapRect: MKMapRect, edgePadding: UIEdgeInsets, animated: Bool)] = []
    var getCurrentRegionCalls: Int = 0

    var onMapTapHandler: ((CLLocationCoordinate2D) -> Void)?
    var onAnnotationSelectedHandler: ((String) -> Void)?

    var showUserLocationCalls: [Bool] = []
    var centerOnUserLocationCalls: [Bool] = []

    var setMapTypeCalls: [MKMapType] = []
    var setUserInteractionEnabledCalls: [Bool] = []
    var setControlsVisibleCalls: [Bool] = []

    // MARK: - Mock State

    var mockCurrentRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    // MARK: - Route Display

    func addRoute(
        coordinates: [CLLocationCoordinate2D],
        color: Color,
        lineWidth: CGFloat,
        identifier: String,
        lineDashPattern: [NSNumber]?
    ) {
        addRouteCalls.append((coordinates, color, lineWidth, identifier, lineDashPattern))
    }

    func removeRoute(identifier: String) {
        removeRouteCalls.append(identifier)
    }

    func clearAllRoutes() {
        clearAllRoutesCalls += 1
    }

    // MARK: - Annotations

    func addAnnotation(
        coordinate: CLLocationCoordinate2D,
        title: String,
        subtitle: String?,
        identifier: String,
        type: OTPAnnotationType,
        routeName: String?,
        routeBackgroundColor: UIColor?,
        routeTextColor: UIColor?
    ) {
        addAnnotationCalls.append((coordinate, title, subtitle, identifier, type, routeName, routeBackgroundColor, routeTextColor))
    }

    func removeAnnotation(identifier: String) {
        removeAnnotationCalls.append(identifier)
    }

    func clearAllAnnotations() {
        clearAllAnnotationsCalls += 1
    }

    // MARK: - Camera Control

    func setRegion(_ region: MKCoordinateRegion, animated: Bool) {
        setRegionCalls.append((region, animated))
        mockCurrentRegion = region
    }

    func setVisibleMapRect(
        _ mapRect: MKMapRect,
        edgePadding: UIEdgeInsets,
        animated: Bool
    ) {
        setVisibleMapRectCalls.append((mapRect, edgePadding, animated))
    }

    func getCurrentRegion() -> MKCoordinateRegion {
        getCurrentRegionCalls += 1
        return mockCurrentRegion
    }

    // MARK: - User Interaction

    func onMapTap(_ handler: @escaping (CLLocationCoordinate2D) -> Void) {
        onMapTapHandler = handler
    }

    func onAnnotationSelected(_ handler: @escaping (String) -> Void) {
        onAnnotationSelectedHandler = handler
    }

    // MARK: - User Location

    func showUserLocation(_ show: Bool) {
        showUserLocationCalls.append(show)
    }

    func centerOnUserLocation(animated: Bool) {
        centerOnUserLocationCalls.append(animated)
    }

    // MARK: - Map Configuration

    func setMapType(_ mapType: MKMapType) {
        setMapTypeCalls.append(mapType)
    }

    func setUserInteractionEnabled(_ enabled: Bool) {
        setUserInteractionEnabledCalls.append(enabled)
    }

    func setControlsVisible(_ visible: Bool) {
        setControlsVisibleCalls.append(visible)
    }

    // MARK: - Test Helpers

    /// Resets all tracking data
    func reset() {
        addRouteCalls.removeAll()
        removeRouteCalls.removeAll()
        clearAllRoutesCalls = 0

        addAnnotationCalls.removeAll()
        removeAnnotationCalls.removeAll()
        clearAllAnnotationsCalls = 0

        setRegionCalls.removeAll()
        setVisibleMapRectCalls.removeAll()
        getCurrentRegionCalls = 0

        onMapTapHandler = nil
        onAnnotationSelectedHandler = nil

        showUserLocationCalls.removeAll()
        centerOnUserLocationCalls.removeAll()

        setMapTypeCalls.removeAll()
        setUserInteractionEnabledCalls.removeAll()
        setControlsVisibleCalls.removeAll()
    }

    /// Simulates a user tapping on the map
    func simulateMapTap(at coordinate: CLLocationCoordinate2D) {
        onMapTapHandler?(coordinate)
    }

    /// Simulates a user selecting an annotation
    func simulateAnnotationSelection(identifier: String) {
        onAnnotationSelectedHandler?(identifier)
    }
}
