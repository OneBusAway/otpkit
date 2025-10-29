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
        default:
            DirectionLegUnknownView(leg: leg)
        }
    }
}
