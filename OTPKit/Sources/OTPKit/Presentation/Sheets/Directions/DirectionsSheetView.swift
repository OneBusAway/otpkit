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

    static let tipDetent: PresentationDetent = .fraction(0.3)

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
        .presentationDragIndicator(.visible)
        .presentationDetents(
            [DirectionsSheetView.tipDetent, .medium, .large], selection: $sheetDetent
        )
        .interactiveDismissDisabled()
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }

    private func handleTap(coordinate: CLLocationCoordinate2D, itemId: String) {
        mapCoordinator.centerOn(coordinate: coordinate)
        scrollToItem = itemId
        sheetDetent = DirectionsSheetView.tipDetent
    }
}

#Preview {
    @State var sheetVisible = true
    @State var directionSheetDetent = DirectionsSheetView.tipDetent
    let trip = Trip(origin: PreviewHelpers.createOrigin(), destination: PreviewHelpers.createDestination(), itinerary: PreviewHelpers.buildItin(legsCount: 2))

    VStack {
        Text("HI")
    }
    .sheet(isPresented: $sheetVisible) {
        DirectionsSheetView(
            trip: trip, sheetDetent: $directionSheetDetent
        )
        .environmentObject(PreviewHelpers.mockTripPlannerViewModel())
    }
}

#Preview {
    @State var directionSheetDetent = DirectionsSheetView.tipDetent
    let trip = Trip(origin: PreviewHelpers.createOrigin(), destination: PreviewHelpers.createDestination(), itinerary: PreviewHelpers.buildItin(legsCount: 2))
    DirectionsSheetView(
        trip: trip, sheetDetent: $directionSheetDetent
    )
}
