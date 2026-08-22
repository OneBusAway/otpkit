//
//  TripPlannerChrome.swift
//  OTPKit
//

import Foundation

/// How `TripPlannerView` frames its own content.
public enum TripPlannerChrome: Sendable, Equatable {
    /// Wrap the planner in its own `NavigationStack`, navigation title and close
    /// button. Suits a full-screen or modally presented planner, and is the default
    /// so existing integrations are unaffected.
    case standalone

    /// Render the planner body alone, leaving the navigation container, title and
    /// close affordance to the host.
    ///
    /// For hosts that present the planner inside navigation they already own — a
    /// sheet in their own stack, say — where `standalone` would produce two headers
    /// and two close buttons. The host owns dismissal in this mode, so `onClose` is
    /// never invoked: the control that would call it belongs to the host. Leave
    /// `onClose` nil rather than passing a closure that cannot fire.
    ///
    /// The host also inherits the cleanup the close button used to perform, so call
    /// `TripPlanner.reset()` at the point of dismissal — not on view disappearance,
    /// which also fires when the host pushes another screen or backgrounds the app:
    ///
    /// ```swift
    /// .sheet(isPresented: $showingPlanner, onDismiss: { planner.reset() }) {
    ///     NavigationStack {
    ///         planner.createTripPlannerView(chrome: .embedded)
    ///             .navigationTitle("Plan a trip")
    ///     }
    /// }
    /// ```
    case embedded
}
