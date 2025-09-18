//
//  BottomSheetConfiguration.swift
//  OTPKit
//
//  Created by Manu on 2025-09-18.
//

import Foundation
import CoreGraphics

/// Configuration options for customizing the appearance and behavior of the bottom sheet
public struct BottomSheetConfiguration {
    /// Corner radius of the bottom sheet in points
    public let cornerRadius: CGFloat

    /// Whether the sheet can be dismissed by user interaction
    public let isDismissible: Bool

    /// Whether tapping the backdrop (area behind the sheet) dismisses the sheet
    public let isDismissOnBackdrop: Bool

    /// Initial position when the sheet is first presented
    public let initialPosition: BottomSheetPosition

    /// Array of positions that the sheet supports for user interaction
    public let supportedPositions: [BottomSheetPosition]

    /// Whether to show the drag indicator (grabber) at the top of the sheet
    public let showGrabber: Bool

    /// Animation duration for position changes in seconds
    public let animationDuration: TimeInterval

    /// Creates a new bottom sheet configuration
    /// - Parameters:
    ///   - cornerRadius: Corner radius in points (default: 12.0)
    ///   - isDismissible: Whether the sheet can be dismissed (default: true)
    ///   - isDismissOnBackdrop: Whether backdrop tap dismisses (default: true)
    ///   - initialPosition: Starting position (default: .half)
    ///   - supportedPositions: Available positions (default: [.tip, .half, .full])
    ///   - showGrabber: Whether to show drag indicator (default: true)
    ///   - animationDuration: Animation speed (default: 0.3)
    public init(
        cornerRadius: CGFloat = 42.0,
        isDismissible: Bool = true,
        isDismissOnBackdrop: Bool = true,
        initialPosition: BottomSheetPosition = .half,
        supportedPositions: [BottomSheetPosition] = [.tip, .half, .full],
        showGrabber: Bool = true,
        animationDuration: TimeInterval = 0.3
    ) {
        // Validate configuration
        precondition(cornerRadius >= 0, "Corner radius must be non-negative")
        precondition(animationDuration > 0, "Animation duration must be positive")
        precondition(!supportedPositions.isEmpty, "At least one position must be supported")
        precondition(supportedPositions.contains(initialPosition), "Initial position must be in supported positions")

        self.cornerRadius = cornerRadius
        self.isDismissible = isDismissible
        self.isDismissOnBackdrop = isDismissOnBackdrop
        self.initialPosition = initialPosition
        self.supportedPositions = supportedPositions
        self.showGrabber = showGrabber
        self.animationDuration = animationDuration
    }
}

// MARK: - Predefined Configurations
public extension BottomSheetConfiguration {
    /// Default configuration suitable for most use cases
    static let `default` = BottomSheetConfiguration()

    /// Configuration for a modal-style sheet that requires explicit dismissal
    static let modal = BottomSheetConfiguration(
        isDismissible: false,
        isDismissOnBackdrop: false,
        initialPosition: .half,
        supportedPositions: [.half, .full]
    )

    /// Configuration for a compact sheet that only shows tip and half positions
    static let compact = BottomSheetConfiguration(
        initialPosition: .tip,
        supportedPositions: [.tip, .half]
    )

    /// Configuration for a full-screen prioritized sheet
    static let fullScreen = BottomSheetConfiguration(
        initialPosition: .full,
        supportedPositions: [.half, .full]
    )
}
