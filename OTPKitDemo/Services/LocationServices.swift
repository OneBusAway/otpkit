//
//  LocationServices.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import Foundation
import MapKit

struct SearchCompletions: Identifiable {
    let id = UUID()
    let title: String
    let subTitle: String
}

class LocationService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter

    @Published var completions = [SearchCompletions]()

    init(completer: MKLocalSearchCompleter = MKLocalSearchCompleter()) {
        self.completer = completer
        super.init()
        self.completer.delegate = self
    }

    func update(queryFragment: String) {
        completer.resultTypes = .pointOfInterest
        completer.queryFragment = queryFragment
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results.map { .init(title: $0.title, subTitle: $0.subtitle) }
    }
}
