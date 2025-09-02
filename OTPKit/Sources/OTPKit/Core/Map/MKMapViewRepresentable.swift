//
//  MKMapViewRepresentable.swift
//  OTPKit
//
//  Created by OTPKit on 2025-09-02.
//

import SwiftUI
import MapKit

/// A SwiftUI representable wrapper for MKMapView that can be used with OTPKit
/// This allows host apps to provide their own MKMapView instance while still using SwiftUI
public struct MKMapViewRepresentable: UIViewRepresentable {
    
    // MARK: - Properties
    
    /// The map provider adapter that will be used by OTPKit
    @Binding var mapProvider: OTPMapProvider?
    
    /// Initial region for the map
    let initialRegion: MKCoordinateRegion
    
    /// Whether to show user location
    let showsUserLocation: Bool
    
    /// Map configuration options
    let mapType: MKMapType
    
    // MARK: - Initialization
    
    /// Creates a new MKMapView representable
    /// - Parameters:
    ///   - mapProvider: Binding to store the map provider adapter
    ///   - initialRegion: Initial region to display
    ///   - showsUserLocation: Whether to show user location
    ///   - mapType: Type of map to display
    public init(
        mapProvider: Binding<OTPMapProvider?>,
        initialRegion: MKCoordinateRegion,
        showsUserLocation: Bool = true,
        mapType: MKMapType = .standard
    ) {
        self._mapProvider = mapProvider
        self.initialRegion = initialRegion
        self.showsUserLocation = showsUserLocation
        self.mapType = mapType
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        // Configure map view
        mapView.region = initialRegion
        mapView.showsUserLocation = showsUserLocation
        mapView.mapType = mapType
        mapView.showsCompass = true
        mapView.showsScale = true
        
        // Create and store the adapter
        let adapter = MKMapViewAdapter(mapView: mapView)
        DispatchQueue.main.async {
            self.mapProvider = adapter
        }
        
        return mapView
    }
    
    public func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update map view properties if needed
        mapView.showsUserLocation = showsUserLocation
        mapView.mapType = mapType
    }
    
    public static func dismantleUIView(_ mapView: MKMapView, coordinator: Coordinator) {
        // Clean up to prevent memory leaks
        mapView.delegate = nil
        mapView.removeFromSuperview()
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    public class Coordinator: NSObject {
        // Coordinator can be used for additional delegate handling if needed
    }
}

/// A convenience view that creates an MKMapView and provides it to OTPKit
public struct OTPMapView: View {
    
    // MARK: - Properties
    
    @State private var mapProvider: OTPMapProvider?
    
    let initialRegion: MKCoordinateRegion
    let showsUserLocation: Bool
    let mapType: MKMapType
    private let onMapReadyCallback: (MapCoordinator) -> Void
    
    // MARK: - Initialization
    
    /// Creates a new OTP map view
    /// - Parameters:
    ///   - initialRegion: Initial region to display
    ///   - showsUserLocation: Whether to show user location
    ///   - mapType: Type of map to display
    ///   - onMapReady: Callback when map is ready with coordinator
    public init(
        initialRegion: MKCoordinateRegion,
        showsUserLocation: Bool = true,
        mapType: MKMapType = .standard,
        onMapReady: @escaping (MapCoordinator) -> Void
    ) {
        self.initialRegion = initialRegion
        self.showsUserLocation = showsUserLocation
        self.mapType = mapType
        self.onMapReadyCallback = onMapReady
    }
    
    // MARK: - Body
    
    public var body: some View {
        MKMapViewRepresentable(
            mapProvider: $mapProvider,
            initialRegion: initialRegion,
            showsUserLocation: showsUserLocation,
            mapType: mapType
        )
        .onAppear {
            if let provider = mapProvider {
                // Create coordinator with actual map provider
                let coordinator = MapCoordinator(mapProvider: provider)
                onMapReadyCallback(coordinator)
            }
        }
    }
}