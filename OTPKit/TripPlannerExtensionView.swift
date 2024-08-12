//
//  TripPlannerExtensionView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 12/08/24.
//

import MapKit
import SwiftUI


/// Main Extension View that take Map as it's content
/// This simplify all the process of making the Trip Planner UI
public struct TripPlannerExtensionView<MapContent: View>: View {
    @StateObject private var sheetEnvironment = OriginDestinationSheetEnvironment()
    @EnvironmentObject private var tripPlanner: TripPlannerService

    @State private var directionSheetDetent: PresentationDetent = .fraction(0.2)

    private let mapContent: () -> MapContent

    public init(@ViewBuilder mapContent: @escaping () -> MapContent) {
        self.mapContent = mapContent
    }

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
                mapContent()
                    .onTapGesture { tappedLocation in
                        handleMapTap(proxy: proxy, tappedLocation: tappedLocation)
                    }
            }
            .sheet(isPresented: $sheetEnvironment.isSheetOpened) {
                OriginDestinationSheetView()
                    .environmentObject(sheetEnvironment)
                    .environmentObject(tripPlanner)
            }
            .sheet(isPresented: isPlanResponsePresented) {
                TripPlannerSheetView()
                    .presentationDetents([.medium, .large])
                    .interactiveDismissDisabled()
                    .environmentObject(tripPlanner)
            }
            .sheet(isPresented: isStepsViewPresented, onDismiss: {
                tripPlanner.resetTripPlanner()
            }) {
                DirectionSheetView(sheetDetent: $directionSheetDetent)
                    .presentationDetents([.fraction(0.2), .medium, .large], selection: $directionSheetDetent)
                    .interactiveDismissDisabled()
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.2)))
                    .environmentObject(tripPlanner)
            }

            overlayContent
        }
        .onAppear {
            tripPlanner.checkIfLocationServicesIsEnabled()
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
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

    private func handleMapTap(proxy: MapProxy, tappedLocation: CGPoint) {
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
}
