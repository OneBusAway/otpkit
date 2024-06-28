//
//  LocationServices.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import Foundation
import MapKit

/// LocationServiceSearchCompletions is the main data model for `LocationService`
/// This will be utilized as list object
struct LocationServiceSearchCompletions: Identifiable {
    let id = UUID()
    let title: String
    let subTitle: String
}

/// LocationService is the main class that's responsible for maanging MKLocalSearchCompleter
class LocationService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter

    @Published var completions = [LocationServiceSearchCompletions]()

    init(completer: MKLocalSearchCompleter = MKLocalSearchCompleter()) {
        self.completer = completer
        super.init()
        self.completer.delegate = self
    }

    /// update method responsible for updating the queryFragement of `completer`
    /// - Parameter queryFragment: this manage the searched query for `completer`
    func update(queryFragment: String) {
        completer.resultTypes = .pointOfInterest
        completer.queryFragment = queryFragment
    }

    /// completerDidUpdateResults is method that finished the search functionality and upadate the `completer`.
    /// This is required function from `MKLocalSearchCompleterDelegate`
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results.map { .init(title: $0.title, subTitle: $0.subtitle) }
    }
}
