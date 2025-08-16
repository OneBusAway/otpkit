//
//  TripPlannerView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI
import MapKit

/// Main view for planning trips, showing map, controls, and results.
public struct TripPlannerView: View {
    /// ViewModel managing trip planning state and logic
    @StateObject private var tripPlannerVM: TripPlannerViewModel
    /// Currently selected location mode (origin or destination)
    @State private var selectedMode: LocationMode = .origin

    /// OTP configuration for the planner
    let otpConfig: OTPConfiguration

    /// Initializes the TripPlannerView with optional origin and destination
    public init(otpConfig: OTPConfiguration, origin: Location? = nil, destination: Location? = nil) {
        let tripPlannerVM = TripPlannerViewModel(config: otpConfig)
        origin.map(tripPlannerVM.setOrigin)
        destination.map(tripPlannerVM.setDestination)
        self._tripPlannerVM = StateObject(wrappedValue: tripPlannerVM)
        self.otpConfig = otpConfig
    }

    public var body: some View {
        ZStack {
            mapView
            if tripPlannerVM.isLoading { loadingOverlay }
            if !tripPlannerVM.showingPolyline { bottomControls }
            if tripPlannerVM.showingPolyline { previewControls }
        }
        .environment(\.otpTheme, otpConfig.themeConfiguration)
        .environmentObject(tripPlannerVM)
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
        MapLocationSelectorView(otpConfig: otpConfig, locationMode: selectedMode)
    }

    /// Overlay shown while trip is being planned
    var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))

                    Text("Planning your trip...")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top)
                }
            }
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
            closeButton
            Spacer()
            if let itinerary = tripPlannerVM.previewItinerary {
                tripPreviewControl(for: itinerary)
            }
        }
    }

    /// Button to close the itinerary preview
    var closeButton: some View {
        HStack {
            Spacer()
            Button(action: tripPlannerVM.clearPreview) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
            }
            .padding()
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
            
        case .routeDetails:
            Text("Route Details")
        case .dateTime:
            Text("Date Time")
        case .settings:
            Text("Settings")
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
