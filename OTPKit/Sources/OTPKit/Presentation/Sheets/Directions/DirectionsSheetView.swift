//
//  DirectionsSheetView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 08/08/24.
//

import SwiftUI
import MapKit

/// A sheet view that displays step-by-step directions to the destination
struct DirectionsSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel
    @EnvironmentObject private var mapCoordinator: MapCoordinator
    @Environment(\.otpTheme) private var theme
    @State private var showEndConfirmation = false

    let trip: Trip
    @Binding var sheetDetent: PresentationDetent
    @State private var scrollToItem: String?

    public init(trip: Trip, sheetDetent: Binding<PresentationDetent>) {
        self.trip = trip
        _sheetDetent = sheetDetent
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                PagedDirectionsView(trip: trip) { leg, id in
                    print("Leg tapped with id: \(id)")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") {
                        showEndConfirmation = true
                    }
                }
            }
            .confirmationDialog(
                "End Trip?",
                isPresented: $showEndConfirmation,
                titleVisibility: .visible
            ) {
                Button("End Trip", role: .destructive) {
                    tripPlannerVM.resetTripPlanner()
                }
                Button("No", role: .cancel) {}
            } message: {
                Text("Are you sure you want to end this trip?")
            }
        }
    }

    private func handleTap(coordinate: CLLocationCoordinate2D, itemId: String) {
        mapCoordinator.centerOn(coordinate: coordinate)
        scrollToItem = itemId
        sheetDetent = .fraction(0.2)
    }
}

#Preview {
    @State var sheetVisible = true
    @State var directionSheetDetent: PresentationDetent = .fraction(0.2)
    let trip = Trip(origin: PreviewHelpers.createOrigin(), destination: PreviewHelpers.createDestination(), itinerary: PreviewHelpers.buildItin(legsCount: 2))

    VStack {
        Text("HI")
    }
    .sheet(isPresented: $sheetVisible) {
        DirectionsSheetView(
            trip: trip, sheetDetent: $directionSheetDetent
        )
        .presentationDragIndicator(.visible)
        .presentationDetents([.fraction(0.2), .medium, .large], selection: $directionSheetDetent)
        .interactiveDismissDisabled()
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .environmentObject(PreviewHelpers.mockTripPlannerViewModel())
    }
}

#Preview {
    @State var directionSheetDetent: PresentationDetent = .fraction(0.2)
    let trip = Trip(origin: PreviewHelpers.createOrigin(), destination: PreviewHelpers.createDestination(), itinerary: PreviewHelpers.buildItin(legsCount: 2))
    DirectionsSheetView(
        trip: trip, sheetDetent: $directionSheetDetent
    )
}
