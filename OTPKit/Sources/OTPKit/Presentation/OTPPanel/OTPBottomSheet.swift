//
//  OTPBottomSheet.swift
//  OTPKit
//
//  Created by Manu on 2025-09-18.
//

import UIKit
import SwiftUI
import FloatingPanel

/// A bottom sheet implementation specifically designed for presenting OTPKit's trip planning interface
///
/// This class provides a convenient way to present the OTPView as a floating bottom sheet
/// with configurable appearance and behavior. It handles the creation of the OTPView internally
/// and manages the FloatingPanel presentation. It automatically responds to route preview
/// notifications to provide Apple Maps-style behavior.
///
/// ## Usage
/// ```swift
/// let bottomSheet = OTPBottomSheet(
///     otpConfig: config,
///     apiService: apiService,
///     mapProvider: mapProvider
/// )
/// bottomSheet.delegate = self
/// bottomSheet.present(on: viewController)
/// ```
public class OTPBottomSheet {

    // MARK: - Properties

    /// The underlying FloatingPanel controller managing the presentation
    private var floatingPanelController: FloatingPanelController?

    /// Reference to the parent view controller
    private weak var parentViewController: UIViewController?

    /// Current configuration used for the sheet
    private var currentConfiguration: BottomSheetConfiguration?

    /// Delegate for receiving sheet state change notifications
    public weak var delegate: OTPBottomSheetDelegate?

    /// Position before preview started (for restoration)
    private var positionBeforePreview: BottomSheetPosition?

    /// OTP configuration for the system
    private let otpConfig: OTPConfiguration

    /// API service for making requests
    private let apiService: APIService

    /// Map provider for operations
    private let mapProvider: OTPMapProvider

    // MARK: - Initialization

    /// Creates a new OTPBottomSheet instance
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
    }

    // MARK: - Presentation & Dismissal

    /// Presents the OTPView as a bottom sheet
    /// - Parameters:
    ///   - origin: Optional starting location
    ///   - destination: Optional destination location
    ///   - viewController: Parent view controller to present on
    ///   - configuration: Bottom sheet appearance and behavior configuration
    ///   - completion: Optional completion handler called after presentation
    public func present(
        origin: Location? = nil,
        destination: Location? = nil,
        on viewController: UIViewController,
        configuration: BottomSheetConfiguration = .default,
        completion: (() -> Void)? = nil
    ) {
        // Validate inputs
        guard floatingPanelController == nil else {
            assertionFailure("Bottom sheet is already presented")
            return
        }

        // Store references
        self.parentViewController = viewController
        self.currentConfiguration = configuration

        // Notify delegate
        delegate?.bottomSheetWillPresent(self)

        // Create and configure the floating panel
        setupFloatingPanel(with: configuration)

        // Create the OTP content
        let otpView = createOTPView(
            origin: origin,
            destination: destination
        )

        // Set up the hosting controller
        setupHostingController(with: otpView)

        // Set up notification observers for route preview coordination
        setupNotificationObservers()

        // Present the panel
        viewController.present(floatingPanelController!, animated: true) { [weak self] in
            self?.delegate?.bottomSheetDidPresent(self!)
            completion?()
        }
    }

    /// Dismisses the bottom sheet
    /// - Parameters:
    ///   - animated: Whether to animate the dismissal
    ///   - completion: Optional completion handler called after dismissal
    public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let panel = floatingPanelController else {
            completion?()
            return
        }

        delegate?.bottomSheetWillDismiss(self)

        panel.dismiss(animated: animated) { [weak self] in
            guard let self = self else { return }
            self.cleanup()
            self.delegate?.bottomSheetDidDismiss(self)
            completion?()
        }
    }

    // MARK: - State Management

    /// Moves the sheet to a specific position
    /// - Parameters:
    ///   - position: Target position
    ///   - animated: Whether to animate the transition
    public func moveToPosition(_ position: BottomSheetPosition, animated: Bool = true) {
        guard let panel = floatingPanelController else { return }
        panel.move(to: position.floatingPanelState, animated: animated)
    }

    /// Returns the current position of the sheet
    /// - Returns: Current bottom sheet position
    public func getCurrentPosition() -> BottomSheetPosition {
        guard let panel = floatingPanelController else { return .half }
        return BottomSheetPosition(from: panel.state)
    }

    /// Checks if the sheet is currently presented
    /// - Returns: True if the sheet is presented, false otherwise
    public var isPresented: Bool {
        return floatingPanelController != nil
    }

    // MARK: - Private Methods

    /// Sets up the FloatingPanel controller with the given configuration
    private func setupFloatingPanel(with configuration: BottomSheetConfiguration) {
        floatingPanelController = FloatingPanelController()

        guard let panel = floatingPanelController else { return }

        // Configure layout
        let layout = CustomBottomSheetLayout(configuration: configuration)
        panel.layout = layout
        panel.delegate = self

        // Configure interaction
        panel.isRemovalInteractionEnabled = configuration.isDismissible
        panel.backdropView.dismissalTapGestureRecognizer.isEnabled = configuration.isDismissOnBackdrop

        // Configure appearance
        if configuration.showGrabber {
            panel.surfaceView.grabberHandle.isHidden = false
        }

        panel.surfaceView.layer.cornerRadius = configuration.cornerRadius
    }

    /// Creates the OTPView with the provided parameters
    private func createOTPView(
        origin: Location?,
        destination: Location?
    ) -> OTPView {
        return OTPView(
            otpConfig: otpConfig,
            apiService: apiService,
            mapProvider: mapProvider,
            origin: origin,
            destination: destination
        )
    }

    /// Sets up the UIHostingController with the OTPView
    private func setupHostingController(with otpView: OTPView) {
        guard let panel = floatingPanelController else { return }

        let hostingController = UIHostingController(rootView: otpView)
        hostingController.view.backgroundColor = .clear

        panel.set(contentViewController: hostingController)
    }

    /// Sets up notification observers for route preview coordination
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMoveSheetToTip),
            name: Notifications.moveSheetToTip,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRestoreSheetPosition),
            name: Notifications.restoreSheetPosition,
            object: nil
        )

    }

    /// Handles start route preview notification
    @objc private func handleMoveSheetToTip() {
        guard isPresented else { return }

        // Store current position for restoration
        positionBeforePreview = getCurrentPosition()

        // Move to tip position for better route visibility
        moveToPosition(.tip, animated: true)
    }

    /// Handles end route preview notification
    @objc private func handleRestoreSheetPosition() {
        guard isPresented else { return }

        // Restore to previous position or default to half
        let targetPosition = positionBeforePreview ?? .half
        moveToPosition(targetPosition, animated: true)

        // Clear stored position
        positionBeforePreview = nil
    }


    /// Cleans up resources when the sheet is dismissed
    private func cleanup() {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)

        floatingPanelController = nil
        parentViewController = nil
        currentConfiguration = nil
        positionBeforePreview = nil
    }
}

// MARK: - FloatingPanelControllerDelegate

extension OTPBottomSheet: FloatingPanelControllerDelegate {
    public func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        let position = BottomSheetPosition(from: fpc.state)
        delegate?.bottomSheetDidChangePosition(position)
    }
}
