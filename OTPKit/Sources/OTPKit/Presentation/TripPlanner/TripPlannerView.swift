//
//  TripPlannerView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI
import MapKit

/// Main view for planning trips, showing controls and results.
/// Full-screen interface with navigation bar, top controls, and inline results.
struct TripPlannerView: View {
    /// ViewModel managing trip planning state and logic
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel
    /// Map coordinator for managing map operations
    @EnvironmentObject private var mapCoordinator: MapCoordinator
    /// Currently selected location mode (origin or destination)
    @State private var selectedMode: LocationMode = .origin

    @State private var directionSheetDetent: PresentationDetent = .fraction(0.2)

    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss

    /// OTP configuration for the planner
    let otpConfig: OTPConfiguration

    /// Initializes the TripPlannerView with configuration
    init(otpConfig: OTPConfiguration) {
        self.otpConfig = otpConfig
    }

    public var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    // Top controls for location selection and trip planning
                    TopControlsOverlay(selectedMode: $selectedMode)
                        .padding(.bottom, 24)

                    // Trip results (shown inline when available)
                    if !tripPlannerVM.itineraries.isEmpty {
                        tripResultsSection
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    // Bottom spacer for proper scrolling and safe area
                    Spacer(minLength: 120)
                }
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Trip Planning")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        tripPlannerVM.resetTripPlanner()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                // Notify when the view disappears to restore navigation UI
                NotificationCenter.default.post(
                    name: Notification.Name("TripPlannerDismissed"),
                    object: nil
                )
            }
            .overlay {
                // Loading overlay
                if tripPlannerVM.isLoading {
                    LoadingOverlay()
                }
            }
        }
        .errorCard(
            isPresented: tripPlannerVM.showingError,
            message: tripPlannerVM.errorMessage ?? "An error occurred",
            onDismiss: clearError
        )
        .sheet(item: $tripPlannerVM.activeSheet, content: sheetView)
    }

    // MARK: - Trip Results Section

    private var tripResultsSection: some View {
        TripPlannerResultsView(
            availableItineraries: tripPlannerVM.itineraries,
            onItinerarySelected: tripPlannerVM.handleItinerarySelection,
            onItineraryPreview: tripPlannerVM.handleItineraryPreview
        )
    }
}


// MARK: - Sheet Content
private extension TripPlannerView {
    /// Returns the appropriate sheet view for the given sheet type
    @ViewBuilder
    func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
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
    .environmentObject(MapCoordinator(mapProvider: MKMapViewAdapter(mapView: MKMapView())))
}
