//
//  MapState.swift
//  OTPKit
//
//  Created by Manu on 2025-07-11.
//
import Foundation
import SwiftUI
import MapKit

@Observable
class MapState {
    var region: MapCameraPosition
    var previewItinerary: Itinerary?
    var showingPolyline = false

    init(region: MapCameraPosition) {
        self.region = region
    }

    func showPreview(for itinerary: Itinerary) {
        previewItinerary = itinerary
        showingPolyline = true
        animateToItinerary(itinerary)
    }

    func hidePreview() {
        previewItinerary = nil
        showingPolyline = false
    }

    private func animateToItinerary(_ itinerary: Itinerary) {
        let coordinates = extractCoordinates(from: itinerary)
        guard coordinates.count > 1 else { return }

        let polyline = MKPolyline(coordinates: coordinates,
                                  count: coordinates.count)

        let paddedRect = polyline.boundingMapRect
            .insetBy(dx: -1_000, dy: -1_000)

        withAnimation {
            region = .rect(paddedRect)
        }
    }

    private func extractCoordinates(from itinerary: Itinerary) -> [CLLocationCoordinate2D] {
        itinerary.legs.flatMap { leg in
            leg.decodePolyline() ?? []
        }
    }
}
