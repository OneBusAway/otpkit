//
//  OTPBottomSheetDelegate.swift
//  OTPKit
//
//  Created by Manu on 2025-09-18.
//

import Foundation

/// Delegate protocol for bottom sheet state changes and interactions
public protocol OTPBottomSheetDelegate: AnyObject {
    /// Called when the bottom sheet position changes
    /// - Parameter position: The new position of the bottom sheet
    func bottomSheetDidChangePosition(_ position: BottomSheetPosition)

    /// Called when the bottom sheet is about to be presented
    /// - Parameter bottomSheet: The bottom sheet instance
    func bottomSheetWillPresent(_ bottomSheet: OTPBottomSheet)

    /// Called when the bottom sheet has been presented
    /// - Parameter bottomSheet: The bottom sheet instance
    func bottomSheetDidPresent(_ bottomSheet: OTPBottomSheet)

    /// Called when the bottom sheet is about to be dismissed
    /// - Parameter bottomSheet: The bottom sheet instance
    func bottomSheetWillDismiss(_ bottomSheet: OTPBottomSheet)

    /// Called when the bottom sheet has been dismissed
    /// - Parameter bottomSheet: The bottom sheet instance
    func bottomSheetDidDismiss(_ bottomSheet: OTPBottomSheet)
}

// MARK: - Default Implementations
public extension OTPBottomSheetDelegate {
    func bottomSheetWillPresent(_ bottomSheet: OTPBottomSheet) {}
    func bottomSheetDidPresent(_ bottomSheet: OTPBottomSheet) {}
    func bottomSheetWillDismiss(_ bottomSheet: OTPBottomSheet) {}
    func bottomSheetDidDismiss(_ bottomSheet: OTPBottomSheet) {}
}