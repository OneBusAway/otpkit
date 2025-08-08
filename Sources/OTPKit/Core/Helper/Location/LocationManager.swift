//
//  LocationManager.swift
//  OTPKit
//
//  Created by Manu on 2025-07-14.
//

import Foundation
import CoreLocation

public class LocationManager {
    private let geocoder = CLGeocoder()
    
    public init() {}
    
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
            print("Geocoding failed: \(error.localizedDescription)")
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
    public func getCurrentLocation() -> Location? {
        let locationManager = CLLocationManager()
        guard let location = locationManager.location else { return nil }
        
        return Location(
            title: "Current Location",
            subTitle: "Your current GPS location",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
} 
