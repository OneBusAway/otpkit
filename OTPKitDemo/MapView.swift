//
//  MapView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import MapKit
import OTPKit
import SwiftUI

struct MapView: View {
    @EnvironmentObject private var tripPlanner: TripPlannerService

    var body: some View {
        TripPlannerExtensionView {
            Map(position: $tripPlanner.currentCameraPosition, interactionModes: .all) {
                tripPlanner.generateMarkers()
                tripPlanner.generateMapPolyline()
                    .stroke(.blue, lineWidth: 5)
            }
            .mapControls {
                if !tripPlanner.isMapMarkingMode {
                    MapUserLocationButton()
                    MapPitchToggle()
                }
            }
        }
        .environmentObject(tripPlanner)
    }
}

#Preview {
    let planner = TripPlannerService(
        apiClient: RestAPI(baseURL: URL(string: "https://otp.prod.sound.obaweb.org/otp/routers/default/")!),
        locationManager: CLLocationManager(),
        searchCompleter: MKLocalSearchCompleter()
    )

    return MapView()
        .environmentObject(planner)
}
