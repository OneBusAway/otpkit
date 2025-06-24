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

    private var selectedMapPoints = TripMapMarkers()

    public var isMapMarkingMode = false
    public var currentCameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    public var originName = OriginDestinationState.origin.name.capitalized
    public var destinationName = OriginDestinationState.destination.name.capitalized

    // User Location
    var currentLocation: Location?
    private let locationManager: CLLocationManager
    private var currentLocations = [CLLocation]()

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
            guard let coordinate = selectedMapPoints.origin?.item.placemark.coordinate else {
                return
            }
            originCoordinate = coordinate
        case .destination:
            guard let coordinate = selectedMapPoints.destination?.item.placemark.coordinate else {
                return
            }
            destinationCoordinate = coordinate
        }
    }

    /// Appends a marker for the given location
    ///
    /// - Parameter location: The location to add a marker for
    public func appendMarker(location: Location) {

        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)

        let placeMark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placeMark)
        mapItem.name = "Finding location..."

        let markerItem = MarkerItem(item: mapItem)

        selectedMapPoints[originDestinationState] = markerItem

        // Get accurate location name in background
        let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        reverseGeoCode(clLocation) { [weak self] locationName in
            guard let self = self else { return }

            // Update marker with real location name once geocoding completes
            self.updateMarkerName(coordinate: coordinate, newName: locationName)
        }
    }

    /// Updates an existing marker's name after geocoding completes
    private func updateMarkerName(coordinate: CLLocationCoordinate2D, newName: String) {
        let placeMark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placeMark)
        mapItem.name = newName

        let updatedMarkerItem = MarkerItem(item: mapItem)

        switch originDestinationState {
        case .origin:
            originName = updatedMarkerItem.item.name ?? "...."
            selectedMapPoints.origin = updatedMarkerItem
        case .destination:
            destinationName = updatedMarkerItem.item.name ?? "...."
            selectedMapPoints.destination = updatedMarkerItem
        }
    }

    /// Adds origin or destination data based on the current state
    public func addOriginDestinationData() {
        switch originDestinationState {
        case .origin:
            originName = selectedMapPoints.origin?.item.name ?? "Location unknown"
            originCoordinate = selectedMapPoints.origin?.item.placemark.coordinate
        case .destination:
            destinationName = selectedMapPoints.destination?.item.name ?? "Location unknown"
            destinationCoordinate = selectedMapPoints.destination?.item.placemark.coordinate
        }

        checkAndFetchTripPlanner()
    }

    /// Removes origin or destination data based on the current state
    public func removeOriginDestinationData() {
        switch originDestinationState {
        case .origin:
            originName = OriginDestinationState.origin.name.capitalized
            originCoordinate = nil
            selectedMapPoints.origin = nil
        case .destination:
            destinationName = OriginDestinationState.destination.name.capitalized
            destinationCoordinate = nil
            selectedMapPoints.destination = nil
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
        ForEach(selectedMapPoints.allMarkers, id: \.id) { markerItem in
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
        selectedMapPoints.reset()
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

        // Check and Cache last location to avoid multiple geocoding requests
        let isLatestLocation = currentLocations.contains {
            $0.coordinate.latitude == location.coordinate.latitude
            && $0.coordinate.longitude == location.coordinate.longitude
        }

        guard !isLatestLocation else {
            return
        }
        currentLocations.append(location)

        reverseGeoCode(location) { [weak self] locationName in
            guard let self = self else {
                return
            }

            DispatchQueue.main.async {
                self.currentLocation = Location(
                    title: locationName,
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
}

// MARK: - Get Place Address Information

extension TripPlannerService {
    /// Performs reverse geocoding to get a readable location name
    private func reverseGeoCode(
        _ location: CLLocation,
        completion: @escaping (
            String
        ) -> Void
    ){
        let geoCoder = CLGeocoder()

        geoCoder.reverseGeocodeLocation(location) { placeMarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                completion("Unknown Location")
                return
            }

            guard let placeMark = placeMarks?.first else {
                completion("Unknown Location")
                return
            }

            let locationName = self.formatLocationName(from: placeMark)
            completion(locationName)
        }
    }

    /// Formats a readable location name from a placemark
    private func formatLocationName(from placeMark: CLPlacemark) -> String {
        if let name = placeMark.name {
            return name
        }

        // street address associated with this placed mark
        if let thoroughfare = placeMark.thoroughfare {
            if let subToroughFare = placeMark.subThoroughfare {
                return "\(subToroughFare) \(thoroughfare)"
            }
            return thoroughfare
        }

        // Try city name if cannot get the street address
        if let locality = placeMark.locality {
            return locality
        }

        return "Unknown Location"
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
