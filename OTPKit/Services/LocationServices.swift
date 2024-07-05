//
//  LocationServices.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import Foundation
import MapKit
import OTPKit

/// LocationService is the main class that's responsible for managing MKLocalSearchCompleter
public final class LocationService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter

    @Published var completions = [Location]()

    init(completer: MKLocalSearchCompleter = MKLocalSearchCompleter()) {
        self.completer = completer
        super.init()
        self.completer.delegate = self
    }

    /// update method responsible for updating the queryFragement of `completer`
    /// - Parameter queryFragment: this manage the searched query for `completer`

    public func update(queryFragment: String) {
        completer.resultTypes = .query
        completer.queryFragment = queryFragment
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