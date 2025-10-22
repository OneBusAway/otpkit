//
//  OTPView.swift
//  OTPKit
//
//  Created by Manu on 2025-08-21.
//

import SwiftUI
import MapKit

/// Root view that provides TripPlannerViewModel as environment object to all child views
public struct OTPView: View {
    /// ViewModel managing trip planning state and logic
    @StateObject private var tripPlannerVM: TripPlannerViewModel

    /// Map coordinator for managing map operations
    @StateObject private var mapCoordinator: MapCoordinator

    /// OTP configuration for the planner
    private let otpConfig: OTPConfiguration

    /// Initializes the OTPView with a map provider, configuration, and optional locations
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
        TripPlannerView(otpConfig: otpConfig)
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
    }
}

#Preview {
    let mapView = MKMapView()
    let mapProvider = MKMapViewAdapter(mapView: mapView)

    return OTPView(
        otpConfig: OTPConfiguration(
            otpServerURL: URL(string: "https://example.com")!
        ),
        apiService: PreviewHelpers.MockAPIService(),
        mapProvider: mapProvider
    )
}
