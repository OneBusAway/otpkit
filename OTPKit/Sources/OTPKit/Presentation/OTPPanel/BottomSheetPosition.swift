//
//  BottomSheetPosition.swift
//  OTPKit
//
//  Created by Manu on 2025-09-18.
//

import Foundation
import FloatingPanel

/// Represents the possible positions of the bottom sheet
public enum BottomSheetPosition: CaseIterable {
    /// Minimal position showing just a tip of the sheet
    case tip
    /// Half-screen position covering approximately 50% of the screen
    case half
    /// Full-screen position covering most of the screen
    case full

    /// Human-readable description of the position
    public var description: String {
        switch self {
        case .tip:
            return "Tip"
        case .half:
            return "Half"
        case .full:
            return "Full"
        }
    }

    /// Maps BottomSheetPosition to FloatingPanelState
    internal var floatingPanelState: FloatingPanelState {
        switch self {
        case .tip:
            return .tip
        case .half:
            return .half
        case .full:
            return .full
        }
    }

    /// Creates BottomSheetPosition from FloatingPanelState
    internal init(from floatingPanelState: FloatingPanelState) {
        switch floatingPanelState {
        case .tip:
            self = .tip
        case .half:
            self = .half
        case .full:
            self = .full
        default:
            self = .half // Default fallback
        }
    }
}