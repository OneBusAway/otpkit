//
//  Untitled.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 10/29/25.
//

import SwiftUI

/// A wrapper for the various `DirectionLeg{Type}View`s.
struct DirectionLegView: View {
    let leg: Leg

    var body: some View {
        switch leg.mode {
        case "BUS", "TRAM":
            DirectionLegVehicleView(leg: leg)
        case "WALK":
            DirectionLegWalkView(leg: leg)
        // OTP 2.x spells bicycle legs "BICYCLE" (rental rides included);
        // "BIKE" is the OTP 1.x REST spelling.
        case "BICYCLE", "BIKE":
            DirectionLegBikeView(leg: leg)
        default:
            DirectionLegUnknownView(leg: leg)
        }
    }
}
