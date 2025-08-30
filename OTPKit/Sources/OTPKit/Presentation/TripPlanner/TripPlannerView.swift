//
//  TripPlannerView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI
import MapKit

/// Main view for planning trips, showing map, controls, and results.
struct TripPlannerView: View {
    /// ViewModel managing trip planning state and logic
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel
    /// Currently selected location mode (origin or destination)
    @State private var selectedMode: LocationMode = .origin

    @State private var directionSheetDetent: PresentationDetent = .fraction(0.2)

    /// OTP configuration for the planner
    let otpConfig: OTPConfiguration

    /// Initializes the TripPlannerView with configuration
    init(otpConfig: OTPConfiguration) {
        self.otpConfig = otpConfig
    }

    public var body: some View {
        ZStack {
            mapView
            if !tripPlannerVM.showingPolyline { bottomControls }
            if tripPlannerVM.showingPolyline { previewControls }

            if tripPlannerVM.isLoading { LoadingOverlay() }
        }
        .errorCard(
            isPresented: tripPlannerVM.showingError,
            message: tripPlannerVM.errorMessage ?? "An error occurred",
            onDismiss: clearError
        )
        .sheet(item: $tripPlannerVM.activeSheet, content: sheetView)
    }
}

// MARK: - View Components
private extension TripPlannerView {
    /// Map view for selecting locations
    var mapView: some View {
        MapLocationSelectorView(locationMode: selectedMode)
    }

    /// Controls shown at the bottom when not previewing a route
    var bottomControls: some View {
        VStack {
            Spacer()
            BottomControlsOverlay(selectedMode: $selectedMode)
        }
    }

    /// Controls shown when previewing a selected itinerary
    var previewControls: some View {
        VStack {
            Spacer()
            if let itinerary = tripPlannerVM.selectedItinerary,
               tripPlannerVM.activeSheet != .directions {
                tripPreviewControl(for: itinerary)
            }
        }
    }

    /// Control for previewing and starting a trip
    func tripPreviewControl(for itinerary: Itinerary) -> some View {
        TripPreviewControl(
            itinerary: itinerary,
            onCancel: tripPlannerVM.clearPreview,
            onStart: tripPlannerVM.handleItinerarySelection
        )
    }
}

// MARK: - Sheet Content
private extension TripPlannerView {
    /// Returns the appropriate sheet view for the given sheet type
    @ViewBuilder
    func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
        case .tripResults:
            TripPlannerResultsView(
                availableItineraries: tripPlannerVM.itineraries,
                onItinerarySelected: tripPlannerVM.handleItinerarySelection,
                onItineraryPreview: tripPlannerVM.handleItineraryPreview
            )

        case .locationOptions:
            LocationOptionsSheet(
                selectedMode: selectedMode,
                onLocationSelected: handleLocationSelection
            )
            .presentationBackground(.ultraThickMaterial)

        case .search:
            SearchSheetView(
                selectedMode: selectedMode,
                onLocationSelected: handleLocationSelection
            )

        case .directions:
            DirectionsSheetView(
                sheetDetent: $directionSheetDetent
            )
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.2), .medium, .large], selection: $directionSheetDetent)
            .interactiveDismissDisabled()
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.2)))

        case .advancedOptions:
            AdvancedOptionsSheet()
        }
    }
}

// MARK: - Actions
private extension TripPlannerView {
    /// Clears the error state in the view model
    func clearError() {
        tripPlannerVM.errorMessage = nil
        tripPlannerVM.showingError = false
    }

    /// Handles location selection for the current mode
    func handleLocationSelection(_ location: Location) {
        tripPlannerVM.handleLocationSelection(location, for: selectedMode)
    }
}

#Preview {
    TripPlannerView(
        otpConfig: .init(
            otpServerURL: URL(string: "example")!,
            region: .automatic
        )
    )
    .environmentObject(PreviewHelpers.mockTripPlannerViewModel())
}
