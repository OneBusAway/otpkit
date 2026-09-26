//
//  TripPlannerViewModel+EmptyPlan.swift
//  OTPKit
//
//  Copyright © Open Transit Software Foundation
//  This source code is licensed under the Apache 2.0 license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
// MARK: - Empty plan notification

extension TripPlannerViewModel {
    /// Tells the host that the plan came back with nothing usable, with the endpoints it was planned between.
    func postTripPlanEmpty(reason: String) {
        var userInfo: [String: Any] = [Notifications.tripPlanEmptyReasonKey: reason]
        if let origin = selectedOrigin {
            userInfo[Notifications.tripPlanEmptyOriginLatitudeKey] = origin.latitude
            userInfo[Notifications.tripPlanEmptyOriginLongitudeKey] = origin.longitude
        }
        if let destination = selectedDestination {
            userInfo[Notifications.tripPlanEmptyDestinationLatitudeKey] = destination.latitude
            userInfo[Notifications.tripPlanEmptyDestinationLongitudeKey] = destination.longitude
        }
        notificationCenter.post(name: Notifications.tripPlanEmpty, object: nil, userInfo: userInfo)
    }
}
