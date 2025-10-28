//
//  MKMapViewAdapter.swift
//  OTPKit
//
//  Created by OTPKit on 2025-09-02.
//

import Foundation
import MapKit
import SwiftUI
import UIKit
import OSLog

/// Adapter that allows an MKMapView to be used as an OTPMapProvider
public class MKMapViewAdapter: NSObject, OTPMapProvider {

    // MARK: - Properties

    private weak var mapView: MKMapView?
    private var routeOverlays: [String: MKPolyline] = [:]
    private var annotations: [String: MKAnnotation] = [:]
    private var tapHandler: ((CLLocationCoordinate2D) -> Void)?
    private var annotationSelectedHandler: ((String) -> Void)?

    // MARK: - Initialization

    /// Creates an adapter for the provided MKMapView
    /// - Parameter mapView: The MKMapView to adapt
    public init(mapView: MKMapView) {
        self.mapView = mapView
        super.init()
        setupMapView()
    }

    deinit {
        // Clean up to prevent retain cycles
        mapView?.delegate = nil
        if let gestureRecognizers = mapView?.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if recognizer.delegate === self {
                    mapView?.removeGestureRecognizer(recognizer)
                }
            }
        }
    }

    private func setupMapView() {
        guard let mapView = mapView else { return }
        mapView.delegate = self

        // Add tap gesture recognizer for map taps
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapGesture.delegate = self
        mapView.addGestureRecognizer(tapGesture)
    }

    // MARK: - Route Display

    public func addRoute(
        coordinates: [CLLocationCoordinate2D],
        color: Color,
        lineWidth: CGFloat,
        identifier: String,
        lineDashPattern: [NSNumber]? = nil
    ) {
        Logger.main.debug("Adding Route")
        guard let mapView = mapView else { return }

        // Remove existing route with same identifier if present
        removeRoute(identifier: identifier)

        // Create polyline
        let polyline = ColoredPolyline(coordinates: coordinates, count: coordinates.count)
        polyline.color = UIColor(color)
        polyline.lineWidth = lineWidth
        polyline.identifier = identifier
        polyline.lineDashPattern = lineDashPattern

        // Store and add to map
        routeOverlays[identifier] = polyline
        mapView.addOverlay(polyline)
    }

    public func removeRoute(identifier: String) {
        guard let mapView = mapView,
              let overlay = routeOverlays[identifier] else { return }

        mapView.removeOverlay(overlay)
        routeOverlays.removeValue(forKey: identifier)
    }

    public func clearAllRoutes() {
        guard let mapView = mapView else { return }

        let overlays = Array(routeOverlays.values)
        mapView.removeOverlays(overlays)
        routeOverlays.removeAll()
    }

    // MARK: - Annotations

    public func addAnnotation(
        coordinate: CLLocationCoordinate2D,
        title: String,
        subtitle: String?,
        identifier: String,
        type: OTPAnnotationType,
        routeName: String? = nil,
        routeBackgroundColor: UIColor? = nil,
        routeTextColor: UIColor? = nil
    ) {
        guard let mapView = mapView else { return }

        // Remove existing annotation with same identifier
        removeAnnotation(identifier: identifier)

        // Create annotation
        let annotation = OTPPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        annotation.subtitle = subtitle
        annotation.identifier = identifier
        annotation.annotationType = type
        annotation.routeName = routeName
        annotation.routeBackgroundColor = routeBackgroundColor
        annotation.routeTextColor = routeTextColor

        // Store and add to map
        annotations[identifier] = annotation
        mapView.addAnnotation(annotation)
    }

    public func removeAnnotation(identifier: String) {
        guard let mapView = mapView,
              let annotation = annotations[identifier] else { return }

        mapView.removeAnnotation(annotation)
        annotations.removeValue(forKey: identifier)
    }

    public func clearAllAnnotations() {
        guard let mapView = mapView else { return }

        let annotationList = Array(annotations.values)
        mapView.removeAnnotations(annotationList)
        annotations.removeAll()
    }

    // MARK: - Camera Control

    public func setRegion(_ region: MKCoordinateRegion, animated: Bool) {
        mapView?.setRegion(region, animated: animated)
    }

    public func setVisibleMapRect(
        _ mapRect: MKMapRect,
        edgePadding: UIEdgeInsets,
        animated: Bool
    ) {
        mapView?.setVisibleMapRect(mapRect, edgePadding: edgePadding, animated: animated)
    }

    public func getCurrentRegion() -> MKCoordinateRegion {
        return mapView?.region ?? MKCoordinateRegion()
    }

    // MARK: - User Interaction

    public func onMapTap(_ handler: @escaping (CLLocationCoordinate2D) -> Void) {
        self.tapHandler = handler
    }

    public func onAnnotationSelected(_ handler: @escaping (String) -> Void) {
        self.annotationSelectedHandler = handler
    }

    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        guard let mapView = mapView else { return }

        let location = gesture.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

        tapHandler?(coordinate)
    }

    // MARK: - User Location

    public func showUserLocation(_ show: Bool) {
        mapView?.showsUserLocation = show
    }

    public func centerOnUserLocation(animated: Bool) {
        guard let mapView = mapView,
              let userLocation = mapView.userLocation.location else { return }

        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: animated)
    }

    // MARK: - Map Configuration

    public func setMapType(_ mapType: MKMapType) {
        mapView?.mapType = mapType
    }

    public func setUserInteractionEnabled(_ enabled: Bool) {
        mapView?.isUserInteractionEnabled = enabled
    }

    public func setControlsVisible(_ visible: Bool) {
        guard let mapView = mapView else { return }
        mapView.showsCompass = visible
        mapView.showsScale = visible
    }
}

// MARK: - MKMapViewDelegate

extension MKMapViewAdapter: MKMapViewDelegate {

    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? ColoredPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = polyline.color
            renderer.lineWidth = polyline.lineWidth
            renderer.lineDashPattern = polyline.lineDashPattern
            renderer.lineCap = .square

            return renderer
        }

        return MKOverlayRenderer(overlay: overlay)
    }

    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Don't customize user location
        if annotation is MKUserLocation {
            return nil
        }

        guard let otpAnnotation = annotation as? OTPPointAnnotation else {
            return nil
        }

        // Use custom view for route legend annotations
        if otpAnnotation.annotationType == .routeLegend {
            let identifier = "RouteNameAnnotation"
            var routeView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? RouteNameAnnotationView

            if routeView == nil {
                routeView = RouteNameAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                routeView?.annotation = annotation
            }

            if let routeName = otpAnnotation.routeName {
                routeView?.configure(
                    routeName: routeName,
                    backgroundColor: otpAnnotation.routeBackgroundColor,
                    textColor: otpAnnotation.routeTextColor
                )
            }

            return routeView
        }

        // Use standard marker view for other annotation types
        let identifier = "OTPAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        // Customize based on type
        annotationView?.markerTintColor = UIColor(otpAnnotation.annotationType.color)
        annotationView?.glyphImage = UIImage(systemName: otpAnnotation.annotationType.systemImageName)

        return annotationView
    }

    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let otpAnnotation = view.annotation as? OTPPointAnnotation else { return }
        annotationSelectedHandler?(otpAnnotation.identifier)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MKMapViewAdapter: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Custom Classes

/// Custom MKPolyline subclass that stores color and identifier information
class ColoredPolyline: MKPolyline {
    var color: UIColor = .blue
    var lineWidth: CGFloat = 3.0
    var identifier: String = ""
    var lineDashPattern: [NSNumber]?
}

/// Custom annotation view for displaying route names/numbers
class RouteNameAnnotationView: MKAnnotationView {
    private let label = UILabel()
    private let badgeView = UIView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        // Disable callout
        canShowCallout = false

        // Setup badge container view
        badgeView.layer.cornerRadius = 6
        badgeView.layer.masksToBounds = true
        addSubview(badgeView)

        // Setup label
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textAlignment = .center
        badgeView.addSubview(label)

        // Set a default frame size
        frame = CGRect(x: 0, y: 0, width: 40, height: 24)
    }

    func configure(routeName: String, backgroundColor: UIColor?, textColor: UIColor?) {
        label.text = routeName

        // Use provided colors or defaults
        badgeView.backgroundColor = backgroundColor ?? .systemBlue
        label.textColor = textColor ?? .white

        // Size to fit the text with padding
        label.sizeToFit()
        let padding: CGFloat = 8
        let width = max(label.frame.width + padding * 2, 24) // Minimum width of 24
        let height: CGFloat = 20

        badgeView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        label.frame = CGRect(x: padding, y: 0, width: width - padding * 2, height: height)

        // Center the badge in the annotation view
        frame = CGRect(x: 0, y: 0, width: width, height: height)
        centerOffset = CGPoint(x: 0, y: 0)
    }
}

/// Custom MKPointAnnotation subclass that stores type and identifier information
class OTPPointAnnotation: MKPointAnnotation {
    var identifier: String = ""
    var annotationType: OTPAnnotationType = .searchResult

    // Properties for route legend annotations
    var routeName: String?
    var routeBackgroundColor: UIColor?
    var routeTextColor: UIColor?
}

// MARK: - UIColor Extension

extension UIColor {
    /// Creates a UIColor from a hex string (e.g., "FF0000" or "#FF0000")
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b: CGFloat

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 3 {
            r = CGFloat((rgb & 0xF00) >> 8) / 15.0
            g = CGFloat((rgb & 0x0F0) >> 4) / 15.0
            b = CGFloat(rgb & 0x00F) / 15.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
