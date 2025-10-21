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
    public static let startRoutePreview = Notification.Name("OTPKit.StartRoutePreview")

    /// Posted when route preview ends - bottom sheet should restore position
    public static let endRoutePreview = Notification.Name("OTPKit.EndRoutePreview")
}
