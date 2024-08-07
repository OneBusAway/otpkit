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

    // API Client
    private let apiClient = RestAPI(
        baseURL: URL(string: "https://otp.prod.sound.obaweb.org/otp/routers/default/")!
    )

    // Trip Planner
    @Published public var planResponse: OTPResponse?
    @Published public var isFetchingResponse = false
    @Published public var tripPlannerErrorMessage: String?
    @Published public var selectedItinerary: Itinerary?

    // Origin Destination
    @Published public var originDestinationState: OriginDestinationState = .origin
    @Published public var originCoordinate: CLLocationCoordinate2D?
    @Published public var destinationCoordinate: CLLocationCoordinate2D?

    // Location Search
    private let completer: MKLocalSearchCompleter
    private let debounceInterval: TimeInterval
    private var debounceTimer: Timer?
    private var currentRegion: MKCoordinateRegion?
    private var searchTask: Task<Void, Never>?

    @Published var completions = [Location]()

    // Map Extension
    @Published public var selectedMapPoint: [String: MarkerItem?] = [
        "origin": nil,
        "destination": nil
    ]

    @Published public var isMapMarkingMode = false
    @Published public var currentCameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    @Published public var originName = "Origin"
    @Published public var destinationName = "Destination"

    // User Location
    @Published var currentLocation: Location?
    var locationManager: CLLocationManager = .init()

    // MARK: - Initialization

    override private init() {
        completer = MKLocalSearchCompleter()
        debounceInterval = 1
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

    private func updateCompleterRegion() {
        if let region = currentRegion {
            completer.region = region
        }
    }

    // MARK: - Map Extension Methods

    public func selectAndRefreshCoordinate() {
        switch originDestinationState {
        case .origin:
            guard let coordinate = selectedMapPoint["origin"]??.item.placemark.coordinate else { return }
            originCoordinate = coordinate
        case .destination:
            guard let coordinate = selectedMapPoint["destination"]??.item.placemark.coordinate else { return }
            destinationCoordinate = coordinate
        }
    }

    public func appendMarker(location: Location) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let mapItem = MKMapItem(placemark: .init(coordinate: coordinate))
        mapItem.name = location.title
        let markerItem = MarkerItem(item: mapItem)
        switch originDestinationState {
        case .origin:
            selectedMapPoint["origin"] = markerItem
            changeMapCamera(mapItem)
        case .destination:
            selectedMapPoint["destination"] = markerItem
            changeMapCamera(mapItem)
        }
    }

    public func addOriginDestinationData() {
        switch originDestinationState {
        case .origin:
            originName = selectedMapPoint["origin"]??.item.name ?? "Location unknown"
            originCoordinate = selectedMapPoint["origin"]??.item.placemark.coordinate
        case .destination:
            destinationName = selectedMapPoint["destination"]??.item.name ?? "Location unknown"
            destinationCoordinate = selectedMapPoint["destination"]??.item.placemark.coordinate
        }

        checkAndFetchTripPlanner()
    }

    public func removeOriginDestinationData() {
        switch originDestinationState {
        case .origin:
            originName = "Origin"
            originCoordinate = nil
            selectedMapPoint["origin"] = nil
        case .destination:
            destinationName = "Destination"
            destinationCoordinate = nil
            selectedMapPoint["destination"] = nil
        }
    }

    public func toggleMapMarkingMode(_ isMapMarking: Bool) {
        isMapMarkingMode = isMapMarking
    }

    private func changeMapCamera(_ item: MKMapItem) {
        currentCameraPosition = MapCameraPosition.item(item)
    }

    public func generateMarkers() -> ForEach<[MarkerItem], MarkerItem.ID, Marker<Text>> {
        ForEach(Array(selectedMapPoint.values.compactMap { $0 }), id: \.id) { markerItem in
            Marker(item: markerItem.item)
        }
    }

    public func generateMapPolyline() -> MapPolyline? {
        guard let itinerary = selectedItinerary else { return nil }

        // Use steps to calculate the Location Coordinate
        let coordinates = itinerary.legs.flatMap { leg in
            leg.steps?.compactMap { step in
                CLLocationCoordinate2D(latitude: step.lat, longitude: step.lon)
            } ?? []
        }

        let coodinateExists = !coordinates.isEmpty

        guard coodinateExists else { return nil }

        return MapPolyline(coordinates: coordinates)
    }

    // MARK: - Trip Planner Methods

    private func checkAndFetchTripPlanner() {
        guard originCoordinate != nil,
              destinationCoordinate != nil
        else {
            return
        }

        let fromPlace = formatCoordinate(originCoordinate)
        let toPlace = formatCoordinate(destinationCoordinate)

        isFetchingResponse = true

        Task {
            do {
                let response = try await apiClient.fetchPlan(
                    fromPlace: fromPlace,
                    toPlace: toPlace,
                    time: getCurrentTimeFormatted(),
                    date: getFormattedTodayDate(),
                    mode: "TRANSIT,WALK",
                    arriveBy: false,
                    maxWalkDistance: 1000,
                    wheelchair: false
                )
                DispatchQueue.main.async {
                    self.planResponse = response
                    self.isFetchingResponse = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.tripPlannerErrorMessage = "Failed to fetch data: \(error.localizedDescription)"
                    self.isFetchingResponse = false
                }
            }
        }
    }

    public func resetTripPlanner() {
        planResponse = nil
        selectedMapPoint = [
            "origin": nil,
            "destination": nil
        ]
        destinationCoordinate = nil
        originCoordinate = nil
        originName = "Origin"
        destinationName = "Destination"
        selectedItinerary = nil
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

            self.currentRegion = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            self.updateCompleterRegion()
        }
    }

    public func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        checkLocationAuthorization()
    }
}

// MARK: - Service Extension

extension LocationManagerService {
    func formatCoordinate(_ coordinate: CLLocationCoordinate2D?) -> String {
        guard let coordinate else { return "" }
        return String(format: "%.4f,%.4f", coordinate.latitude, coordinate.longitude)
    }

    func getFormattedTodayDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let today = Date()

        return dateFormatter.string(from: today)
    }

    func getCurrentTimeFormatted() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        let currentDate = Date()

        return dateFormatter.string(from: currentDate)
    }
}
