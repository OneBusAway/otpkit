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

    /// Calculates the approximate height of the sheet based on the current detent
    private var currentSheetHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        switch sheetDetent {
        case DirectionsSheetView.tipDetent: // .fraction(0.3)
            return screenHeight * 0.3
        case .medium:
            return screenHeight * 0.5
        case .large:
            return screenHeight * 0.9 // Approximate, accounting for safe areas
        default:
            return screenHeight * 0.3 // Default to tip height
        }
    }

    public init(trip: Trip, sheetDetent: Binding<PresentationDetent>) {
        self.trip = trip
        _sheetDetent = sheetDetent
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                PagedDirectionsView(trip: trip, onTap: { leg, id in
                    print("Leg tapped with id: \(id)")
                }, onPageChange: handlePageChange)
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

    private func handlePageChange(_ pageId: String) {
        if pageId == "origin" || pageId == "destination" {
            // Show entire trip for origin and destination pages
            mapCoordinator.showItinerary(trip.itinerary)
        } else if pageId.hasPrefix("leg-") {
            // Extract leg index from page ID (format: "leg-0", "leg-1", etc.)
            if let indexString = pageId.split(separator: "-").last,
               let legIndex = Int(indexString),
               legIndex < trip.itinerary.legs.count {
                let leg = trip.itinerary.legs[legIndex]
                // Pass the current sheet height as bottom padding to ensure the leg is fully visible
                mapCoordinator.focusOnLeg(leg, bottomPadding: currentSheetHeight)
            }
        }
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
