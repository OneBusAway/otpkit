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
    @StateObject private var tripPlannerVM: TripPlannerViewModel

    /// Map coordinator for managing map operations
    @StateObject private var mapCoordinator: MapCoordinator

    /// OTP configuration for the planner
    private let otpConfig: OTPConfiguration

    /// Currently selected location mode (origin or destination)
    @State private var selectedMode: LocationMode = .origin

    @State private var directionSheetDetent: PresentationDetent = .fraction(0.2)

    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss

    /// Initializes the TripPlannerView with a map provider, configuration, and optional locations
    /// This is the main entry point for using OTPKit
    /// - Parameters:
    ///   - otpConfig: Configuration containing server URL and theme
    ///   - apiService: Service for making API requests
    ///   - mapProvider: External map provider that OTPKit will control
    ///   - origin: Optional starting location (if nil, current location will be used)
    ///   - destination: Optional destination location
    public init(
        otpConfig: OTPConfiguration,
        apiService: APIService,
        mapProvider: OTPMapProvider,
        origin: Location? = nil,
        destination: Location? = nil
    ) {
        let mapCoordinator = MapCoordinator(mapProvider: mapProvider)
        let tripPlannerVM = TripPlannerViewModel(
            config: otpConfig,
            apiService: apiService,
            mapCoordinator: mapCoordinator
        )
        tripPlannerVM.selectedOrigin = origin
        tripPlannerVM.selectedDestination = destination

        self._tripPlannerVM = StateObject(wrappedValue: tripPlannerVM)
        self._mapCoordinator = StateObject(wrappedValue: mapCoordinator)
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
            .overlay {
                // Loading overlay
                if tripPlannerVM.isLoading {
                    LoadingOverlay()
                }
            }
        }
        .environmentObject(tripPlannerVM)
        .environmentObject(mapCoordinator)
        .environment(\.otpTheme, otpConfig.themeConfiguration)
        .task {
            // Auto-set current location as origin if no origin is provided
            if tripPlannerVM.selectedOrigin == nil {
                await tripPlannerVM.setCurrentLocationAsOrigin()
            }

            // Show user location on the map
            mapCoordinator.showUserLocation(true)
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
    let mapView = MKMapView()
    let mapProvider = MKMapViewAdapter(mapView: mapView)

    TripPlannerView(
        otpConfig: .init(otpServerURL: URL(string: "example")!),
        apiService: PreviewHelpers.MockAPIService(),
        mapProvider: mapProvider
    )
    .environmentObject(MapCoordinator(mapProvider: MKMapViewAdapter(mapView: MKMapView())))
    .frame(height: 320)
}
