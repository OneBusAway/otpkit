//
//  Notifications.swift
//  OTPKit
//
//  Created by Manu on 2025-09-18.
//

import Foundation

/// Notifications for bottom sheet coordination during route preview
public enum Notifications {
    /// Posted when route preview starts - bottom sheet should move to tip position
    public static let moveSheetToTip = Notification.Name("OTPKit.moveSheetToTip")

    /// Posted when route preview ends - bottom sheet should restore position
    public static let restoreSheetPosition = Notification.Name("OTPKit.restoreSheetPosition")

    /// Make the sheet take up the full screen
    public static let moveSheetToFull = Notification.Name("OTPKit.moveSheetToFull")
}
