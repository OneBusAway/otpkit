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

    @StateObject private var userLocationService = UserLocationServices.shared
    @StateObject private var mapExtensionService = MapExtensionServices.shared

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)

    public var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $position, interactionModes: .all) {
                    mapExtensionService
                        .generateMarkers()
                }
                .mapControls {
                    MapUserLocationButton()
                    MapPitchToggle()
                }
                .sheet(isPresented: $sheetEnvironment.isSheetOpened) {
                    OriginDestinationSheetView()
                        .environmentObject(sheetEnvironment)
                }
                .onTapGesture { tappedLocation in
                    guard let coordinate = proxy.convert(tappedLocation, from: .local) else { return }
                    mapExtensionService.appendMarker(coordinate: coordinate)
                }
            }

            VStack {
                Spacer()
                OriginDestinationView()
                    .environmentObject(sheetEnvironment)
            }
        }
        .onAppear {
            userLocationService.checkIfLocationServicesIsEnabled()
        }
    }
}

#Preview {
    MapView()
}
