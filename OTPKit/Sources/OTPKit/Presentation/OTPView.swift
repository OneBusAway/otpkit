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

    /// OTP configuration for the planner
    private let otpConfig: OTPConfiguration

    /// Initializes the OTPView with optional origin and destination
    /// This is the main entry point for using OTPKit
    /// - Parameters:
    ///   - otpConfig: Configuration containing server URL, region, and theme
    ///   - apiService: Service for making API requests
    ///   - origin: Optional starting location (if nil, current location will be used)
    ///   - destination: Optional destination location
    public init(
        otpConfig: OTPConfiguration,
        apiService: APIService,
        origin: Location? = nil,
        destination: Location? = nil
    ) {
        let tripPlannerVM = TripPlannerViewModel(config: otpConfig, apiService: apiService)
        tripPlannerVM.selectedOrigin = origin
        tripPlannerVM.selectedDestination = destination
        self._tripPlannerVM = StateObject(wrappedValue: tripPlannerVM)
        self.otpConfig = otpConfig
    }

    public var body: some View {
        TripPlannerView(otpConfig: otpConfig)
            .environmentObject(tripPlannerVM)
            .environment(\.otpTheme, otpConfig.themeConfiguration)
            .task {
                // Auto-set current location as origin if no origin is provided
                if tripPlannerVM.selectedOrigin == nil {
                    await tripPlannerVM.setCurrentLocationAsOrigin()
                }
            }
    }
}

#Preview {
    OTPView(
        otpConfig: OTPConfiguration(
            otpServerURL: URL(string: "https://example.com")!,
            region: .automatic
        ),
        apiService: PreviewHelpers.MockAPIService()
    )
}
