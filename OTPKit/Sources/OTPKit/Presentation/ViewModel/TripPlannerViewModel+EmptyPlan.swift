//
//  TripPlannerViewModel+EmptyPlan.swift
//  OTPKit
//
//  Copyright © Open Transit Software Foundation
//  This source code is licensed under the Apache 2.0 license found in the
//  LICENSE file in the root directory of this source tree.
//

import CoreLocation
import Foundation

// MARK: - Empty plan notification

extension TripPlannerViewModel {
    /// Tells the host that the plan came back with nothing usable, with the endpoints of the request
    /// that produced it (not the current selection, which the rider may have changed since).
    func postTripPlanEmpty(reason: String, for request: TripPlanRequest) {
        let userInfo: [String: Any] = [
            Notifications.tripPlanEmptyReasonKey: reason,
            Notifications.tripPlanEmptyOriginLatitudeKey: request.origin.latitude,
            Notifications.tripPlanEmptyOriginLongitudeKey: request.origin.longitude,
            Notifications.tripPlanEmptyDestinationLatitudeKey: request.destination.latitude,
            Notifications.tripPlanEmptyDestinationLongitudeKey: request.destination.longitude
        ]
        notificationCenter.post(name: Notifications.tripPlanEmpty, object: nil, userInfo: userInfo)
    }
}
