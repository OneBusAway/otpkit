//
//  SearchCompleterDelegate.swift
//  OTPKit
//
//  Created by Manu on 2025-07-14.
//
import Foundation
import SwiftUI
import MapKit

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
            print("Search completer error: \(error.localizedDescription)")
            self.searchCompletions = []
        }
    }
}
