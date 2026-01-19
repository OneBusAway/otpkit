//
//  OTPBottomSheet.swift
//  OTPKit
//
//  Created by Manu on 2025-09-18.
//

import UIKit
import SwiftUI

/// A container object that wraps all of the OTPKit trip planning functionality.
///
/// This class provides a convenient way to display a `TripPlannerView` with configurable
/// appearance and behavior.
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

    private let notificationCenter: NotificationCenter

    private let viewModel: TripPlannerViewModel

    // MARK: - Initialization

    /// Creates a new TripPlanner instance
    /// - Parameters:
    ///   - otpConfig: Configuration for the OTP system
    ///   - apiService: Service for making API requests
    ///   - mapProvider: Provider for map operations
    ///   - notificationCenter: Notification Center for receiving notifications. Defaults to `NotificationCenter.default`
    public init(
        otpConfig: OTPConfiguration,
        apiService: APIService,
        mapProvider: OTPMapProvider,
        notificationCenter: NotificationCenter = .default
    ) {
        self.otpConfig = otpConfig
        self.apiService = apiService
        self.mapProvider = mapProvider
        self.mapCoordinator = MapCoordinator(mapProvider: mapProvider)
        self.notificationCenter = notificationCenter
        self.viewModel = TripPlannerViewModel(
            config: otpConfig,
            apiService: apiService,
            mapCoordinator: mapCoordinator,
            notificationCenter: notificationCenter
        )

        // TODO: this class should be the one that owns notification sending so that
        // it can be used as the object to remove observers later if needed
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
            .environment(\.otpSearchRegion, viewModel.config.searchRegion)
            .environmentObject(mapCoordinator)
            .environmentObject(viewModel)
    }
}
