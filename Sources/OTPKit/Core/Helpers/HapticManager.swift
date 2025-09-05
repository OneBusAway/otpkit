//
//  HapticManager.swift
//  OTPKit
//
//  Created by Manu on 2025-08-23.
//

import UIKit

/// Manager for providing haptic feedback throughout the app
public class HapticManager {

    /// Shared instance for consistent haptic feedback
    public static let shared = HapticManager()

    private init() {}

    /// Provides light impact feedback for subtle interactions
    public func lightImpact() {
        guard UIApplication.shared.applicationState == .active else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }

    /// Provides selection feedback for picker-like interactions
    public func selection() {
        guard UIApplication.shared.applicationState == .active else { return }
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
    }

    /// Provides success notification feedback
    public func success() {
        guard UIApplication.shared.applicationState == .active else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.success)
    }
}
