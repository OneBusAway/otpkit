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
    @EnvironmentObject private var tripPlanner: TripPlannerService

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var directionSheetDetent: PresentationDetent = .fraction(0.2)

    private var isPlanResponsePresented: Binding<Bool> {
        Binding(
            get: { tripPlanner.planResponse != nil && tripPlanner.isStepsViewPresented == false },
            set: { _ in }
        )
    }

    private var isStepsViewPresented: Binding<Bool> {
        Binding(
            get: { tripPlanner.isStepsViewPresented },
            set: { _ in }
        )
    }

    public var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $tripPlanner.currentCameraPosition, interactionModes: .all) {
                    tripPlanner
                        .generateMarkers()
                    tripPlanner
                        .generateMapPolyline()
                        .stroke(.blue, lineWidth: 5)
                }
                .mapControls {
                    if !tripPlanner.isMapMarkingMode {
                        MapUserLocationButton()
                        MapPitchToggle()
                    }
                }
                .onTapGesture { tappedLocation in
                    if tripPlanner.isMapMarkingMode {
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
                        tripPlanner.appendMarker(location: location)
                    }
                }
                .sheet(isPresented: $sheetEnvironment.isSheetOpened) {
                    OriginDestinationSheetView()
                        .environmentObject(sheetEnvironment)
                        .environmentObject(tripPlanner)
                }
                .sheet(isPresented: isPlanResponsePresented, content: {
                    TripPlannerSheetView()
                        .presentationDetents([.medium, .large])
                        .interactiveDismissDisabled()
                        .environmentObject(tripPlanner)
                })
                .sheet(isPresented: isStepsViewPresented, onDismiss: {
                    tripPlanner.resetTripPlanner()
                }, content: {
                    DirectionSheetView(sheetDetent: $directionSheetDetent)
                        .presentationDetents([.fraction(0.2), .medium, .large], selection: $directionSheetDetent)
                        .interactiveDismissDisabled()
                        .presentationBackgroundInteraction(
                            .enabled(upThrough: .fraction(0.2))
                        )
                        .environmentObject(tripPlanner)
                })
            }

            if tripPlanner.isFetchingResponse {
                ProgressView()
            } else if tripPlanner.isMapMarkingMode {
                MapMarkingView()
                    .environmentObject(tripPlanner)
            } else if let selectedItinerary = tripPlanner.selectedItinerary, !tripPlanner.isStepsViewPresented {
                VStack {
                    Spacer()
                    TripPlannerView(text: selectedItinerary.summary)
                        .environmentObject(tripPlanner)
                }
            } else if tripPlanner.planResponse == nil, tripPlanner.isStepsViewPresented == false {
                VStack {
                    Spacer()
                    OriginDestinationView()
                        .environmentObject(sheetEnvironment)
                        .environmentObject(tripPlanner)
                }
            }
        }
        .onAppear {
            tripPlanner.checkIfLocationServicesIsEnabled()
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
