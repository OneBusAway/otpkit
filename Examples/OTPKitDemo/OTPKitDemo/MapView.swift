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
    @Environment(TripPlannerService.self) private var tripPlanner

    var body: some View {
        ZStack {
            TripPlannerExtensionView {
                Map(position: tripPlanner.currentCameraPositionBinding, interactionModes: .all) {
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
        }

    }
}

#Preview {
    MapView()
}
