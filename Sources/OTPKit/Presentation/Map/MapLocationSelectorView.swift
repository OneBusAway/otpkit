//
//  MapLocationSelectorView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import CoreLocation
import MapKit
import SwiftUI

public struct MapLocationSelectorView: View {
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel
    @State private var mapState: MapState

    let locationMode: LocationMode
    let config: OTPConfiguration
    private let locationManager = LocationManager()

    public init(
        otpConfig: OTPConfiguration,
        locationMode: LocationMode
    ){
        self.config = otpConfig
        self.locationMode = locationMode
        self._mapState = State(initialValue: MapState(region: otpConfig.region))
    }

    public var body: some View {
        MapReader { mapProxy in
            Map(position: $mapState.region) {
                locationAnnotations
                routeOverlay
                if locationMode == .origin { UserAnnotation() }
            }
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapUserLocationButton()
                MapScaleView()
            }
            .onTapGesture { location in
                handleMapTap(at: location, with: mapProxy)
            }
        }
        .onChange(of: tripPlannerVM.previewItinerary) { _, newItinerary in
            updateMapForPreview(newItinerary)
        }
    }
}

// MARK: - Map Content
private extension MapLocationSelectorView {
    @MapContentBuilder
    var locationAnnotations: some MapContent {
        if let origin = tripPlannerVM.selectedOrigin {
            locationAnnotation(for: origin, title: "Origin", color: .green)
        }

        if let destination = tripPlannerVM.selectedDestination {
            locationAnnotation(for: destination, title: "Destination", color: .red)
        }
    }

    @MapContentBuilder
    var routeOverlay: some MapContent {
        if tripPlannerVM.showingPolyline, let polyline = routePolyline {
            // White halo
            polyline.stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 8, lineCap: .round))
            // Main route
            polyline.stroke(Color(.systemBlue), style: StrokeStyle(lineWidth: 7, lineCap: .round))
        }
    }

    func locationAnnotation(for location: Location, title: String, color: Color) -> some MapContent {
        Annotation(title, coordinate: location.coordinate) {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(color)
                .font(.title2)
                .background(Color.white, in: Circle())
        }
    }
}

// MARK: - Event Handlers
private extension MapLocationSelectorView {
    func handleMapTap(at location: CGPoint, with mapProxy: MapProxy) {
        guard !tripPlannerVM.showingPolyline,
              let coordinate = mapProxy.convert(location, from: .local) else { return }

        let tempLocation = Location(
            title: "Finding...",
            subTitle: "Searching for address",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        updateSelectedLocation(with: tempLocation)

        Task {
            if let geocodedLocation = await locationManager.reverseGeocode(coordinate: coordinate) {
                updateSelectedLocation(with: geocodedLocation)
            }
        }
    }

    func updateMapForPreview(_ itinerary: Itinerary?) {
        if let itinerary = itinerary {
            mapState.showPreview(for: itinerary)
        } else {
            mapState.hidePreview()
        }
    }

    func updateSelectedLocation(with location: Location) {
        switch locationMode {
        case .origin: tripPlannerVM.setOrigin(location)
        case .destination: tripPlannerVM.setDestination(location)
        }
    }
}

// MARK: - Computed Properties
private extension MapLocationSelectorView {
    var routePolyline: MapPolyline? {
        guard let itinerary = tripPlannerVM.previewItinerary else { return nil }
        let coordinates = itinerary.legs.compactMap { $0.decodePolyline() }.flatMap { $0 }
        return coordinates.isEmpty ? nil : MapPolyline(coordinates: coordinates)
    }
}

