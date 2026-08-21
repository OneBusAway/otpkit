//
//  TripPlannerView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI
import MapKit

/// How `TripPlannerView` frames its own content.
public enum TripPlannerChrome: Sendable {
    /// Wrap the planner in its own `NavigationStack`, navigation title and close
    /// button. Suits a full-screen or modally presented planner, and is the default
    /// so existing integrations are unaffected.
    case standalone

    /// Render the planner body alone, leaving the navigation container, title and
    /// close affordance to the host.
    ///
    /// For hosts that present the planner inside navigation they already own — a
    /// sheet in their own stack, say — where `standalone` would produce two headers
    /// and two close buttons. The host is then responsible for dismissal, and should
    /// call `TripPlanner.reset()` as it dismisses so the next presentation starts
    /// clean; `onClose` is never invoked in this mode, because the control that
    /// would call it belongs to the host.
    case embedded
}

/// Main view for planning trips, showing controls and results.
///
/// Supplies its own navigation chrome by default; pass `chrome: .embedded` to render
/// the body alone inside a host's own navigation.
public struct TripPlannerView: View {
    /// ViewModel managing trip planning state and logic
    @StateObject private var tripPlannerVM: TripPlannerViewModel

    /// Map coordinator for managing map operations
    @StateObject private var mapCoordinator: MapCoordinator

    /// Currently selected location mode (origin or destination)
    @State private var selectedMode: LocationMode = .origin

    @State private var directionSheetDetent: PresentationDetent = DirectionsSheetView.tipDetent

    /// Whether this view supplies its own navigation container and close button.
    private let chrome: TripPlannerChrome

    private let onClose: VoidBlock

    /// Initializes the TripPlannerView with a map provider, configuration, and optional locations
    /// This is the main entry point for using OTPKit
    /// - Parameters:
    ///   - viewModel: The TripPlannerViewModel
    ///   - mapCoordinator: The MapCoordinator object
    ///   - origin: Optional starting location (if nil, current location will be used)
    ///   - destination: Optional destination location
    ///   - chrome: Whether the view supplies its own navigation container, title and
    ///     close button. Defaults to `.standalone`.
    ///   - onClose: A callback invoked when the close button is tapped. Never called
    ///     when `chrome` is `.embedded`, which renders no close button.
    public init(
        viewModel: TripPlannerViewModel,
        mapCoordinator: MapCoordinator,
        origin: Location? = nil,
        destination: Location? = nil,
        chrome: TripPlannerChrome = .standalone,
        onClose: @escaping VoidBlock
    ) {
        viewModel.selectedOrigin = origin
        viewModel.selectedDestination = destination

        self._tripPlannerVM = StateObject(wrappedValue: viewModel)
        self._mapCoordinator = StateObject(wrappedValue: mapCoordinator)
        self.chrome = chrome
        self.onClose = onClose
    }

    public var body: some View {
        framedContent
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
            message: tripPlannerVM.errorMessage ?? OTPLoc("common.generic_error", comment: "Fallback error message"),
            onDismiss: clearError
        )
        .sheet(item: $tripPlannerVM.activeSheet, content: sheetView)
        .environmentObject(tripPlannerVM)
    }

    // MARK: - Layout

    /// The planner body, identical in both chrome modes. Navigation-scoped modifiers
    /// stay out of here: `navigationTitle` and `toolbar` are no-ops without an
    /// enclosing container, so they belong to the `.standalone` branch alone.
    private var plannerContent: some View {
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
        .overlay {
            // Loading overlay
            if tripPlannerVM.isLoading {
                LoadingOverlay()
            }
        }
    }

    @ViewBuilder
    private var framedContent: some View {
        switch chrome {
        case .standalone:
            NavigationStack {
                plannerContent
                    .navigationTitle(OTPLoc("trip_planner.title", comment: "Title of the trip planning screen"))
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(OTPLoc("common.close", comment: "Close button"), systemImage: "xmark") {
                                tripPlannerVM.resetTripPlanner()
                                self.onClose()
                            }
                        }
                    }
            }
        case .embedded:
            plannerContent
        }
    }

    // MARK: - Trip Results Section

    private var tripResultsSection: some View {
        TripPlannerResultsView(
            availableItineraries: tripPlannerVM.itineraries,
            onItinerarySelected: tripPlannerVM.handleTripStarted,
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

        case .preview(let trip):
            ItineraryDetailsView(
                origin: trip.origin,
                destination: trip.destination,
                itinerary: trip.itinerary
            )

        case .directions(let trip):
            DirectionsSheetView(
                trip: trip,
                sheetDetent: $directionSheetDetent
            )

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
    let otpConfig = PreviewHelpers.mockOTPConfiguration()
    let mapView = MKMapView()
    let mapProvider = MKMapViewAdapter(mapView: mapView)
    let mapCoordinator = MapCoordinator(mapProvider: mapProvider)
    let viewModel = TripPlannerViewModel(
        config: otpConfig,
        apiService: PreviewHelpers.MockAPIService(),
        mapCoordinator: mapCoordinator
    )

    TripPlannerView(
        viewModel: viewModel,
        mapCoordinator: mapCoordinator
    ) {
        print("Close me!")
    }
    .frame(height: 320)
}
