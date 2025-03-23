//
//  TripPlannerService.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 18/07/24.
//

import Foundation
import MapKit
import SwiftUI

// swiftlint:disable file_length
/// Services to manage all functions related to trip planning
@Observable
public final class TripPlannerService: NSObject {
    // MARK: - Properties

    private let apiClient: RestAPI

    // Trip Planner
    public var planResponse: OTPResponse?
    public var isFetchingResponse = false
    public var tripPlannerErrorMessage: String?
    public var selectedItinerary: Itinerary?
    public var isStepsViewPresented = false

    // Origin Destination
    public var originDestinationState: OriginDestinationState = .origin
    public var originCoordinate: CLLocationCoordinate2D?
    public var destinationCoordinate: CLLocationCoordinate2D?

    // Location Search
    private let searchCompleter: MKLocalSearchCompleter
    private let debounceInterval: TimeInterval
    private var debounceTimer: Timer?
    private var currentRegion: MKCoordinateRegion?
    private var searchTask: Task<Void, Never>?

    private let originKey = OriginDestinationState.origin.name
    private let destinationKey = OriginDestinationState.destination.name
    
    var completions = [Location]()

    // Map Extension
    public var selectedMapPoint: [String: MarkerItem?] = [
        "origin": nil,
        "destination": nil
    ]

    public var isMapMarkingMode = false
    public var currentCameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    public var originName = OriginDestinationState.origin.name.capitalized
    public var destinationName = OriginDestinationState.destination.name.capitalized

    // User Location
    var currentLocation: Location?
    private let locationManager: CLLocationManager

    // View Bindings
    public var isStepsViewPresentedBinding: Binding<Bool> {
        Binding(
            get: { self.isStepsViewPresented },
            set: { _ in }
        )
    }

    public var isPlanResponsePresentedBinding: Binding<Bool> {
        Binding(
            get: { self.planResponse != nil && self.isStepsViewPresented == false },
            set: { _ in }
        )
    }

    public var currentCameraPositionBinding: Binding<MapCameraPosition> {
        Binding(
            get: { self.currentCameraPosition },
            set: { _ in }
        )
    }

    // MARK: - Initialization

    /// Initializes a new instance of TripPlannerService
    ///
    /// - Parameters:
    ///   - apiClient: The REST API client for making network requests
    ///   - locationManager: The location manager for handling user location
    ///   - searchCompleter: The search completer for location search functionality
    public init(apiClient: RestAPI, locationManager: CLLocationManager, searchCompleter: MKLocalSearchCompleter) {
        self.apiClient = apiClient
        self.locationManager = locationManager
        self.searchCompleter = searchCompleter
        debounceInterval = 1
        super.init()

        searchCompleter.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    deinit {
        debounceTimer?.invalidate()
        searchCompleter.cancel()
    }

    // MARK: - Location Search Methods

    /// Initiates a local search for `queryFragment`.
    /// This will be debounced, as set by the `debounceInterval` on the initializer.
    /// - Parameter queryFragment: The search term
    public func updateQuery(queryFragment: String) {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            guard let self else { return }
            searchCompleter.resultTypes = .query
            searchCompleter.queryFragment = queryFragment
        }
    }

    private func updateCompleterRegion() {
        if let region = currentRegion {
            searchCompleter.region = region
        }
    }

    // MARK: - Map Extension Methods

    /// Selects and refreshes the coordinate based on the current origin/destination state
    public func selectAndRefreshCoordinate() {
        switch originDestinationState {
        case .origin:
            guard let coordinate = selectedMapPoint[originKey]??.item.placemark.coordinate else { return }
            originCoordinate = coordinate
        case .destination:
            guard let coordinate = selectedMapPoint[destinationKey]??.item.placemark.coordinate else { return }
            destinationCoordinate = coordinate
        }
    }

    /// Appends a marker for the given location
    ///
    /// - Parameter location: The location to add a marker for
    public func appendMarker(location: Location) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let mapItem = MKMapItem(placemark: .init(coordinate: coordinate))
        mapItem.name = location.title
        let markerItem = MarkerItem(item: mapItem)
        switch originDestinationState {
        case .origin:
            selectedMapPoint[originKey] = markerItem
            changeMapCamera(mapItem)
        case .destination:
            selectedMapPoint[destinationKey] = markerItem
            changeMapCamera(mapItem)
        }
    }

    /// Adds origin or destination data based on the current state
    public func addOriginDestinationData() {
        switch originDestinationState {
        case .origin:
            originName = selectedMapPoint[originKey]??.item.name ?? "Location unknown"
            originCoordinate = selectedMapPoint[originKey]??.item.placemark.coordinate
        case .destination:
            destinationName = selectedMapPoint[destinationKey]??.item.name ?? "Location unknown"
            destinationCoordinate = selectedMapPoint[destinationKey]??.item.placemark.coordinate
        }

        checkAndFetchTripPlanner()
    }

    /// Removes origin or destination data based on the current state
    public func removeOriginDestinationData() {
        switch originDestinationState {
        case .origin:
            originName = OriginDestinationState.origin.name.capitalized
            originCoordinate = nil
            selectedMapPoint[originKey] = nil
        case .destination:
            destinationName = OriginDestinationState.destination.name.capitalized
            destinationCoordinate = nil
            selectedMapPoint[destinationKey] = nil
        }
    }

    /// Toggles the map marking mode
    ///
    /// - Parameter isMapMarking: Boolean indicating whether map marking is enabled
    public func toggleMapMarkingMode(_ isMapMarking: Bool) {
        isMapMarkingMode = isMapMarking
    }

    /// Changes the map camera to focus on the given map item
    ///
    /// - Parameter item: The map item to focus on
    public func changeMapCamera(_ item: MKMapItem) {
        currentCameraPosition = MapCameraPosition.item(item)
    }
    
    /// Changes the map camera to focus on the given coordinate
    ///
    /// - Parameter to coordinate: Add the CLLocationCoordinate2D object
    public func changeMapCamera(to coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        currentCameraPosition = .region(region)
    }

    /// Generates markers for the map based on selected points
    ///
    /// - Returns: MapContent containing the markers
    @MainActor
    public func generateMarkers() -> some MapContent {
        ForEach(Array(selectedMapPoint.values.compactMap { $0 }), id: \.id) { markerItem in
            Marker(item: markerItem.item)
        }
    }

    /// Generates a map polyline based on the selected itinerary
    ///
    /// - Returns: MapPolyline object or nil if no valid itinerary is selected
    public func generateMapPolyline() -> MapPolyline? {
        guard let itinerary = selectedItinerary else { return nil }

        // Use steps to calculate the Location Coordinate
        let coordinates = itinerary.legs.flatMap { leg in
            leg.decodePolyline()?.compactMap { coordinate in
                coordinate
            } ?? []
        }

        let coodinateExists = !coordinates.isEmpty

        guard coodinateExists else { return nil }

        return MapPolyline(coordinates: coordinates)
    }

    /// Adjusts the camera to show both origin and destination
    public func adjustOriginDestinationCamera() {
        guard let originCoordinate, let destinationCoordinate else { return }
        // Create a rectangle that encompasses both coordinates
        let minLat = min(originCoordinate.latitude, destinationCoordinate.latitude)
        let maxLat = max(originCoordinate.latitude, destinationCoordinate.latitude)
        let minLon = min(originCoordinate.longitude, destinationCoordinate.longitude)
        let maxLon = max(originCoordinate.longitude, destinationCoordinate.longitude)

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.5,
                                    longitudeDelta: (maxLon - minLon) * 1.5)

        let region = MKCoordinateRegion(center: center, span: span)

        currentCameraPosition = .region(region)
    }

    // MARK: - Trip Planner Methods

    /// Automatically fetch the Trip Planner if there's origin coordinate and destination coordinate
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

    /// Resets all trip planner related data
    public func resetTripPlanner() {
        planResponse = nil
        selectedMapPoint = [
            originKey: nil,
            destinationKey: nil
        ]
        destinationCoordinate = nil
        originCoordinate = nil
        originName = OriginDestinationState.origin.name.capitalized
        destinationName = OriginDestinationState.destination.name.capitalized
        selectedItinerary = nil
        isStepsViewPresented = false
    }

    // MARK: - User Location Methods

    public func checkLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

}

// MARK: - MKLocalSearchCompleterDelegate

extension TripPlannerService: MKLocalSearchCompleterDelegate {
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

extension TripPlannerService: CLLocationManagerDelegate {
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
}

// MARK: - Service Extension

extension TripPlannerService {
    /// Formats a coordinate into a string representation
    ///
    /// - Parameter coordinate: The coordinate to format
    /// - Returns: A string representation of the coordinate
    func formatCoordinate(_ coordinate: CLLocationCoordinate2D?) -> String {
        guard let coordinate else { return "" }
        return String(format: "%.4f,%.4f", coordinate.latitude, coordinate.longitude)
    }

    /// Gets the current date formatted as a string
    ///
    /// - Returns: The formatted date string
    func getFormattedTodayDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let today = Date()

        return dateFormatter.string(from: today)
    }

    /// Gets the current time formatted as a string
    ///
    /// - Returns: The formatted time string
    func getCurrentTimeFormatted() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        let currentDate = Date()

        return dateFormatter.string(from: currentDate)
    }
}

// swiftlint:enable file_length
