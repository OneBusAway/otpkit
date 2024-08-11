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
    @EnvironmentObject private var locationManagerService: TripPlannerService

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var directionSheetDetent: PresentationDetent = .fraction(0.2)

    private var isPlanResponsePresented: Binding<Bool> {
        Binding(
            get: { locationManagerService.planResponse != nil && locationManagerService.isStepsViewPresented == false },
            set: { _ in }
        )
    }

    private var isStepsViewPresented: Binding<Bool> {
        Binding(
            get: { locationManagerService.isStepsViewPresented },
            set: { _ in }
        )
    }

    public var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $locationManagerService.currentCameraPosition, interactionModes: .all) {
                    locationManagerService
                        .generateMarkers()
                    locationManagerService
                        .generateMapPolyline()
                        .stroke(.blue, lineWidth: 5)
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
                        .environmentObject(locationManagerService)
                }
                .sheet(isPresented: isPlanResponsePresented, content: {
                    TripPlannerSheetView()
                        .presentationDetents([.medium, .large])
                        .interactiveDismissDisabled()
                        .environmentObject(locationManagerService)
                })
                .sheet(isPresented: isStepsViewPresented, onDismiss: {
                    locationManagerService.resetTripPlanner()
                }, content: {
                    DirectionSheetView(sheetDetent: $directionSheetDetent)
                        .presentationDetents([.fraction(0.2), .medium, .large], selection: $directionSheetDetent)
                        .interactiveDismissDisabled()
                        .presentationBackgroundInteraction(
                            .enabled(upThrough: .fraction(0.2))
                        )
                        .environmentObject(locationManagerService)
                })
            }

            if locationManagerService.isFetchingResponse {
                ProgressView()
            } else if locationManagerService.isMapMarkingMode {
                MapMarkingView()
                    .environmentObject(locationManagerService)
            } else if locationManagerService.selectedItinerary != nil,
                      locationManagerService.isStepsViewPresented == false {
                VStack {
                    Spacer()
                    TripPlannerView()
                        .environmentObject(locationManagerService)
                }
            } else if locationManagerService.planResponse == nil, locationManagerService.isStepsViewPresented == false {
                VStack {
                    Spacer()
                    OriginDestinationView()
                        .environmentObject(sheetEnvironment)
                        .environmentObject(locationManagerService)
                }
            }
        }
        .onAppear {
            locationManagerService.checkIfLocationServicesIsEnabled()
        }
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
