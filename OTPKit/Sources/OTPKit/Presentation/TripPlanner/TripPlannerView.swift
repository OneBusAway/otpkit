//
//  TripPlannerView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI
import MapKit

/// Main view for planning trips, showing controls and results.
/// The map is provided externally and controlled via MapCoordinator.
struct TripPlannerView: View {
    /// ViewModel managing trip planning state and logic
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel
    /// Map coordinator for managing map operations
    @EnvironmentObject private var mapCoordinator: MapCoordinator
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
            // Note: Map is now provided externally and controlled via MapCoordinator
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
    /// Controls shown at the bottom when not previewing a route
    var bottomControls: some View {
        VStack {
            BottomControlsOverlay(selectedMode: $selectedMode)
            Spacer()
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

        case .locationOptions(let mode):
            LocationOptionsSheet(
                selectedMode: mode,
                onLocationSelected: handleLocationSelection
            )
            .presentationBackground(.ultraThickMaterial)

        case .search(let mode):
            SearchSheetView(
                selectedMode: mode,
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
    func handleLocationSelection(_ location: Location, locationMode: LocationMode) {
        tripPlannerVM.handleLocationSelection(location, for: locationMode)
    }
}

#Preview {
    TripPlannerView(
        otpConfig: .init(
            otpServerURL: URL(string: "example")!
        )
    )
    .environmentObject(PreviewHelpers.mockTripPlannerViewModel())
}
