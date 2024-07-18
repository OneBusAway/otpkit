//
//  LocationServices.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import Foundation
import MapKit

/// Manages everything location such as search completer, etc
public final class LocationService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter

    @Published var completions = [Location]()

    init(completer: MKLocalSearchCompleter = MKLocalSearchCompleter(), debounceInterval: TimeInterval = 0.3) {
        self.completer = completer
        self.debounceInterval = debounceInterval
        super.init()
        self.completer.delegate = self
    }

    deinit {
        debounceTimer?.invalidate()
    }

    private let debounceInterval: TimeInterval

    private var debounceTimer: Timer?

    /// Initiates a local search for `queryFragment`.
    /// This will be debounced, as set by the `debounceInterval` on the initializer.
    /// - Parameter queryFragment: The search term
    public func update(queryFragment: String) {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            guard let self else { return }
            completer.resultTypes = .query
            completer.queryFragment = queryFragment
        }
    }

    /// completerDidUpdateResults is method that finished the search functionality and update the `completer`.
    /// This is required function from `MKLocalSearchCompleterDelegate`
    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions.removeAll()

        for result in completer.results {
            let searchRequest = MKLocalSearch.Request(completion: result)
            let search = MKLocalSearch(request: searchRequest)

            search.start { [weak self] response, error in
                guard let self = self, let response = response else {
                    if let error = error {
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
