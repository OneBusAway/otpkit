//
//  OTPBottomSheetDelegate.swift
//  OTPKit
//
//  Created by Manu on 2025-09-18.
//

import Foundation
import SwiftUI
import UIKit

/// Delegate protocol for bottom sheet state changes and interactions
public protocol OTPBottomSheetDelegate: AnyObject {
    /// Called when the bottom sheet position changes
    /// - Parameter position: The new position of the bottom sheet
    func bottomSheetDidChangePosition(_ position: BottomSheetPosition)

    /// Called when the bottom sheet is about to be presented
    /// - Parameter bottomSheet: The bottom sheet instance
    func bottomSheetWillPresent(_ bottomSheet: TripPlanner)

    /// Called when the bottom sheet has been presented
    /// - Parameter bottomSheet: The bottom sheet instance
    func bottomSheetDidPresent(_ bottomSheet: TripPlanner)

    /// Called when the bottom sheet is about to be dismissed
    /// - Parameter bottomSheet: The bottom sheet instance
    func bottomSheetWillDismiss(_ bottomSheet: TripPlanner)

    /// Called when the bottom sheet has been dismissed
    /// - Parameter bottomSheet: The bottom sheet instance
    func bottomSheetDidDismiss(_ bottomSheet: TripPlanner)

    func presentTripPlannerView(_ tripPlanner: TripPlanner, view: some View)
}

// MARK: - Default Implementations
public extension OTPBottomSheetDelegate {
    func bottomSheetWillPresent(_ bottomSheet: TripPlanner) {}
    func bottomSheetDidPresent(_ bottomSheet: TripPlanner) {}
    func bottomSheetWillDismiss(_ bottomSheet: TripPlanner) {}
    func bottomSheetDidDismiss(_ bottomSheet: TripPlanner) {}
}
