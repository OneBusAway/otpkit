//
//  MapView.swift
//  OTPKitDemo
//
//  Created by Hilmy Veradin on 25/06/24.
//

import MapKit
import OTPKit
import SwiftUI

public struct MapView: View {
    @StateObject private var sheetEnvironment = OriginDestinationSheetEnvironment()
    @ObservedObject private var locationManagerService = LocationManagerService.shared

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

    public var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $locationManagerService.currentCameraPosition, interactionModes: .all) {
                    locationManagerService
                        .generateMarkers()
                }
                .mapControls {
                    if !locationManagerService.isMapMarkingMode {
                        MapUserLocationButton()
                        MapPitchToggle()
                    }
                }
                .onTapGesture { tappedLocation in
                    if locationManagerService.isMapMarkingMode {
                        guard let coordinate = proxy.convert(tappedLocation, from: .local) else { return }
                        let mapItem = MKMapItem(placemark: .init(coordinate: coordinate))
                        let locationTitle = mapItem.name ?? "Location unknown"
                        let locationSubtitle = mapItem.placemark.title ?? "Location unknown"
                        let location = Location(
                            title: locationTitle,
                            subTitle: locationSubtitle,
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude
                        )
                        locationManagerService.appendMarker(location: location)
                    }
                }
                .sheet(isPresented: $sheetEnvironment.isSheetOpened) {
                    OriginDestinationSheetView()
                        .environmentObject(sheetEnvironment)
                }
            }
            if locationManagerService.isMapMarkingMode {
                MapMarkingView()

            } else {
                VStack {
                    Spacer()
                    OriginDestinationView()
                        .environmentObject(sheetEnvironment)
                }
            }
        }
        .onAppear {
            locationManagerService.checkIfLocationServicesIsEnabled()
        }
    }
}

#Preview {
    MapView()
}
