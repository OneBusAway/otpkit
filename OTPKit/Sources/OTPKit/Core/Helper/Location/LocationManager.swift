//
//  LocationManager.swift
//  OTPKit
//
//  Created by Manu on 2025-07-14.
//

import Foundation
import CoreLocation
import Combine
import OSLog

// Singleton manager to handle CoreLocation tasks across the app
public class LocationManager: NSObject, ObservableObject {
    public static let shared = LocationManager()

    private let geocoder = CLGeocoder()
    private let locationManager = CLLocationManager()

    // Publishes the user’s current location updates
    @Published public var currentLocation: CLLocation?
    // Publishes the current permission/authorization status
    @Published public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    // Publishes any error encountered during location updates
    @Published public var locationError: Error?

    public override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    public func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    public func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        locationManager.startUpdatingLocation()
    }

    public func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }

    @MainActor
    public func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> Location? {
        let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
            guard let placemark = placemarks.first else { return nil }

            let title = formatTitle(from: placemark)
            let subtitle = formatSubtitle(from: placemark, title: title)

            return Location(
                title: title,
                subTitle: subtitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            Logger.main.warning("Geocoding failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Formatting Helpers

    private func formatTitle(from placemark: CLPlacemark) -> String {
        if let pointOfInterest = placemark.areasOfInterest?.first {
            // Use POI name (e.g., "Starbucks", "Central Park")
            return pointOfInterest
        } else if let name = placemark.name,
                  !name.contains(placemark.thoroughfare ?? "") {
            // Use place name if it's not just the street address
            return name
        } else {
            // Fall back to street address
            let streetComponents = [placemark.subThoroughfare, placemark.thoroughfare]
                .compactMap { $0 }
            return streetComponents.isEmpty ? "Unknown Location" : streetComponents.joined(separator: " ")
        }
    }

    private func formatSubtitle(from placemark: CLPlacemark, title: String) -> String {
        var components: [String] = []

        // Add street address if different from title
        let streetComponents = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0 }
        let streetAddress = streetComponents.joined(separator: " ")

        if !streetAddress.isEmpty && title != streetAddress {
            components.append(streetAddress)
        }

        // Add area info (neighborhood, city)
        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }

        return components.isEmpty ? "No address available" : components.joined(separator: ", ")
    }

    // MARK: - Current Location

    @MainActor
    public func getCurrentLocation() async -> Location? {
        // Return cached location if available
        if let location = currentLocation {
            return Location(
                title: "Current Location",
                subTitle: "Your current GPS location",
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }

        // Request location if not available
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return nil
        }

        // Try to get a fresh location update
        locationManager.requestLocation()

        // Wait briefly for location update
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        guard let location = currentLocation else { return nil }

        return Location(
            title: "Current Location",
            subTitle: "Your current GPS location",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.locationError = CLError(.locationUnknown)
            }
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
            self.locationError = nil
        }
        manager.stopUpdatingLocation()
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error
        }
        manager.stopUpdatingLocation()
    }
}
