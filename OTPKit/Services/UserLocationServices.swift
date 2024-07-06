//
//  UserLocationServices.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 06/07/24.
//

import Foundation
import MapKit

/// `UserLocationServices` responsible for asking permission, and manage current users location
public final class UserLocationServices: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: Location?

    public static let shared = UserLocationServices()

    var locationManager: CLLocationManager = .init()

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    public func checkIfLocationServicesIsEnabled() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.checkLocationAuthorization()
            }
        }
    }

    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Handle restricted or denied
            break
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }

    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = Location(
                title: "My Location",
                subTitle: "Your current location",
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }

    public func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        checkLocationAuthorization()
    }
}
