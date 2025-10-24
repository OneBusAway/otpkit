//
//  OTPBottomSheet.swift
//  OTPKit
//
//  Created by Manu on 2025-09-18.
//

import UIKit
import SwiftUI
import FloatingPanel

/// A container object that wraps all of the OTPKit trip planning functionality.
///
/// This class provides a convenient way to present `TripPlannerView` as a floating bottom sheet
/// with configurable appearance and behavior. It handles the creation of the `TripPlannerView` internally
/// and manages the `FloatingPanel` presentation. It automatically responds to route preview
/// notifications to provide Apple Maps-style behavior.
///
/// ## Usage
/// ```swift
/// let planner = TripPlanner(
///     otpConfig: config,
///     apiService: apiService,
///     mapProvider: mapProvider
/// )
/// planner.delegate = self
/// planner.present(on: viewController)
/// ```
@MainActor
public class TripPlanner {
    // MARK: - Properties

    /// OTP configuration for the system
    private let otpConfig: OTPConfiguration

    /// API service for making requests
    private let apiService: APIService

    /// Map provider for operations
    private let mapProvider: OTPMapProvider

    private let mapCoordinator: MapCoordinator

    private let viewModel: TripPlannerViewModel

    // MARK: - Initialization

    /// Creates a new TripPlanner instance
    /// - Parameters:
    ///   - otpConfig: Configuration for the OTP system
    ///   - apiService: Service for making API requests
    ///   - mapProvider: Provider for map operations
    public init(
        otpConfig: OTPConfiguration,
        apiService: APIService,
        mapProvider: OTPMapProvider
    ) {
        self.otpConfig = otpConfig
        self.apiService = apiService
        self.mapProvider = mapProvider
        self.mapCoordinator = MapCoordinator(mapProvider: mapProvider)
        self.viewModel = TripPlannerViewModel(config: otpConfig, apiService: apiService, mapCoordinator: mapCoordinator)
    }

    // MARK: - Presentation & Dismissal

    public func createTripPlannerView(origin: Location? = nil, destination: Location? = nil, onClose: @escaping VoidBlock) -> some View {
        let view = TripPlannerView(
            viewModel: viewModel,
            mapCoordinator: mapCoordinator,
            origin: origin,
            destination: destination, onClose: onClose)

        return view
            .environment(\.otpTheme, viewModel.config.themeConfiguration)
            .environmentObject(mapCoordinator)
            .environmentObject(viewModel)
    }
}
