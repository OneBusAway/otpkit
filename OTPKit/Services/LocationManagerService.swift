//
//  LocationManagerService.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 18/07/24.
//

import Foundation
import MapKit
import SwiftUI

public final class LocationManagerService: NSObject, ObservableObject {
    public static let shared = LocationManagerService()

    // MARK: - Properties

    // Origin Destination
    @Published public var originDestinationState: OriginDestinationState = .origin
    @Published public var originCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @Published public var destinationCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    // Location Search
    private let completer: MKLocalSearchCompleter
    private let debounceInterval: TimeInterval
    private var debounceTimer: Timer?
    @Published var completions = [Location]()

    // Map Extension
    @Published public var selectedMapPoint: [String: MarkerItem?] = [
        "origin": nil,
        "destination": nil
    ]

    @Published public var isMapMarkingMode = false

    // User Location
    @Published var currentLocation: Location?
    var locationManager: CLLocationManager = .init()

    // MARK: - Initialization

    override private init() {
        completer = MKLocalSearchCompleter()
        debounceInterval = 0.3
        super.init()

        completer.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    deinit {
        debounceTimer?.invalidate()
    }

    // MARK: - Location Search Methods

    /// Initiates a local search for `queryFragment`.
    /// This will be debounced, as set by the `debounceInterval` on the initializer.
    /// - Parameter queryFragment: The search term
    public func updateQuery(queryFragment: String) {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            guard let self else { return }
            completer.resultTypes = .query
            completer.queryFragment = queryFragment
        }
    }

    // MARK: - Map Extension Methods

    public func selectCoordinate() {
        switch originDestinationState {
        case .origin:
            guard let coordinate = selectedMapPoint["origin"]??.item.placemark.coordinate else { return }
            originCoordinate = coordinate
        case .destination:
            guard let coordinate = selectedMapPoint["destination"]??.item.placemark.coordinate else { return }
            destinationCoordinate = coordinate
        }
    }

    public func appendMarker(coordinate: CLLocationCoordinate2D) {
        let mapItem = MKMapItem(placemark: .init(coordinate: coordinate))
        let markerItem = MarkerItem(item: mapItem)
        switch originDestinationState {
        case .origin:
            selectedMapPoint["origin"] = markerItem
        case .destination:
            selectedMapPoint["destination"] = markerItem
        }
    }

    public func generateMarkers() -> ForEach<[MarkerItem], MarkerItem.ID, Marker<Text>> {
        ForEach(Array(selectedMapPoint.values.compactMap { $0 }), id: \.id) { markerItem in
            Marker(item: markerItem.item)
        }
    }

    public func toggleMapMarkingMode(_ isMapMarking: Bool) {
        // If it's true, then reset the states. When entering the
        if isMapMarking {
            switch originDestinationState {
            case .origin:
                selectedMapPoint["origin"] = nil
            case .destination:
                selectedMapPoint["destination"] = nil
            }
        }
        isMapMarkingMode = isMapMarking
    }

    // MARK: - User Location Methods

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
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationManagerService: MKLocalSearchCompleterDelegate {
    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions.removeAll()

        for result in completer.results {
            let searchRequest = MKLocalSearch.Request(completion: result)
            let search = MKLocalSearch(request: searchRequest)

            search.start { [weak self] response, error in
                guard let self, let response else {
                    if let error {
                        print("Error performing local search: \(error)")
                    }
                    return
                }

                if let mapItem = response.mapItems.first {
                    let completion = Location(
                        title: result.title,
                        subTitle: result.subtitle,
                        latitude: mapItem.placemark.coordinate.latitude,
                        longitude: mapItem.placemark.coordinate.longitude
                    )

                    DispatchQueue.main.async {
                        self.completions.append(completion)
                    }
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManagerService: CLLocationManagerDelegate {
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
