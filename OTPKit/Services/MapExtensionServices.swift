//
//  MapExtensionServices.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 16/07/24.
//

import Foundation
import MapKit
import SwiftUI


/// Manage Map extension such as markers, etc
public final class MapExtensionServices: ObservableObject {
    public static let shared = MapExtensionServices()

    @Published public var selectedMapPoint: [MarkerItem] = []

    public func appendMarker(coordinate: CLLocationCoordinate2D) {
        let mapItem = MKMapItem(placemark: .init(coordinate: coordinate))
        let markerItem = MarkerItem(item: mapItem)
        selectedMapPoint.append(markerItem)
    }

    /// Generate MapKit Marker View
    public func generateMarkers() -> ForEach<[MarkerItem], MarkerItem.ID, Marker<Text>> {
        ForEach(selectedMapPoint, id: \.id) { markerItem in
            Marker(item: markerItem.item)
        }
    }
}
