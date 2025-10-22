//
//  SearchManager.swift
//  OTPKit
//
//  Created by Manu on 2025-07-14.
//

import Foundation
import SwiftUI
import MapKit
import OSLog

/// Manages location search functionality using MapKit's search completer
/// Handles search suggestions, detailed location lookups, and favorites management
@Observable
class SearchManager: NSObject, MKLocalSearchCompleterDelegate {
    var searchCompletions: [MKLocalSearchCompletion] = []
    var isSearching = false

    private let searchCompleter = MKLocalSearchCompleter()

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        searchCompleter.region = MKCoordinateRegion(.world)
    }

    func search(query: String) {
        searchCompleter.queryFragment = query
    }

    func clear() {
        searchCompletions = []
        searchCompleter.queryFragment = ""
    }

    // MARK: - MKLocalSearchCompleterDelegate
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.searchCompletions = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            Logger.main.warning("Search completer error: \(error.localizedDescription)")
            self.searchCompletions = []
        }
    }

    // MARK: - Business Logic Methods

    func performDetailedSearch(for completion: MKLocalSearchCompletion, onLocationSelected: @escaping (Location) -> Void) {
        isSearching = true

        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { response, error in
            DispatchQueue.main.async {
                self.isSearching = false

                guard let response = response,
                      let item = response.mapItems.first else {
                    Logger.main.error("Search error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let location = Location(
                    title: item.name ?? completion.title,
                    subTitle: item.placemark.title ?? completion.subtitle,
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )

                // Add to recent locations
                _ = UserDefaultsServices.shared.saveRecentLocations(data: location)

                onLocationSelected(location)
            }
        }
    }

    func addToFavorites(completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { response, error in
            DispatchQueue.main.async {
                guard let response = response,
                      let item = response.mapItems.first else {
                    Logger.main.error("Failed to get location details for favorites: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                let location = Location(
                    title: item.name ?? completion.title,
                    subTitle: item.placemark.title ?? completion.subtitle,
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )

                let result = UserDefaultsServices.shared.saveFavoriteLocationData(data: location)
                switch result {
                case .success:
                    Logger.main.info("Successfully added to favorites: \(location.title)")
                    HapticManager.shared.success()
                case .failure(let error):
                    Logger.main.error("Failed to add to favorites: \(error.localizedDescription)")
                }
            }
        }
    }
}
