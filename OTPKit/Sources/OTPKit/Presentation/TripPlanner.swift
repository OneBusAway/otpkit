//
//  OTPBottomSheet.swift
//  OTPKit
//
//  Created by Manu on 2025-09-18.
//

import CoreLocation
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

    /// Internal rather than private so tests can observe the state `reset()` clears.
    /// Not part of the public API.
    let mapCoordinator: MapCoordinator

    private let notificationCenter: NotificationCenter

    /// Internal rather than private so tests can observe the state `reset()` clears.
    /// Not part of the public API.
    let viewModel: TripPlannerViewModel

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

    /// Creates the trip planner UI, optionally prefilled.
    ///
    /// - Parameters:
    ///   - origin: Prefilled origin location. Nil leaves any existing selection alone.
    ///   - destination: Prefilled destination location. Nil leaves any existing
    ///     selection alone.
    ///   - viaPoint: An intermediate coordinate every planned trip must pass through —
    ///     the "plan a trip using this bike" entry point passes the vehicle's location.
    ///     Note: OTP servers may require a transit mode in the request to route through
    ///     a via point, so pair this with `.transitBikeRental` rather than `.bikeRental`.
    ///   - transportMode: Preselected transport mode. Ignored when the injected API
    ///     service cannot support it (e.g. rental modes on an OTP 1.x REST backend).
    ///   - chrome: Whether the planner supplies its own navigation container, title
    ///     and close button. Pass `.embedded` when presenting inside navigation the
    ///     host already owns, and call `reset()` when dismissing.
    ///   - onClose: Called when the rider dismisses the planner. Leave it nil when
    ///     `chrome` is `.embedded`, which renders no close button and so can never
    ///     call it.
    public func createTripPlannerView(
        origin: Location? = nil,
        destination: Location? = nil,
        viaPoint: CLLocationCoordinate2D? = nil,
        transportMode: TransportMode? = nil,
        chrome: TripPlannerChrome = .standalone,
        onClose: VoidBlock? = nil
    ) -> some View {
        // The prefill is all-or-nothing: a via point paired with an unsupported mode
        // must not be applied alone, or the planner would route the rider through a
        // rental vehicle's location in a mode that can't use it. Nil parameters
        // leave existing state untouched — here and in `TripPlannerView.init` — so
        // re-invoking the factory is harmless.
        let modeIsAvailable = transportMode.map { viewModel.availableTransportModes.contains($0) } ?? true
        if modeIsAvailable {
            if let transportMode {
                viewModel.selectTransportMode(transportMode)
            }
            if let viaPoint {
                // After the mode change: selecting a mode clears any stale via point.
                viewModel.viaPoint = viaPoint
            }
        }

        let view = TripPlannerView(
            viewModel: viewModel,
            mapCoordinator: mapCoordinator,
            origin: origin,
            destination: destination,
            chrome: chrome,
            onClose: onClose)

        return view
            .environment(\.otpTheme, viewModel.config.themeConfiguration)
            .environment(\.otpSearchRegion, viewModel.config.searchRegion)
            .environmentObject(mapCoordinator)
            .environmentObject(viewModel)
    }

    /// Clears planned trip state and anything drawn for it on the map: the selected
    /// origin, destination and via point, the plan response and selected itinerary,
    /// any error, and the route and location annotations on the map. Trip options and
    /// the transport mode return to their defaults.
    ///
    /// The `.standalone` close button does this on the rider's behalf. A host using
    /// `.embedded` chrome owns the close control instead, so it has to call this as
    /// it dismisses — otherwise the next presentation reopens on the previous trip.
    ///
    /// Call it at the point of dismissal, not from `onDisappear`, which also fires
    /// when the host pushes another screen or the app is backgrounded.
    public func reset() {
        viewModel.resetTripPlanner()
    }
}
