//
//  ItineraryLegsView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 10/26/25.
//

import SwiftUI

typealias LegIDTapHandler = (Leg, String) -> Void

struct ItineraryLegsView: View {
    let itinerary: Itinerary
    let onTap: LegIDTapHandler?

    init(itinerary: Itinerary, onTap: LegIDTapHandler? = nil) {
        self.itinerary = itinerary
        self.onTap = onTap
    }

    var body: some View {
        ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, leg in
            switch leg.mode {
            case "BUS", "TRAM":
                DirectionLegVehicleView(leg: leg).onTapGesture {
                    onTap?(leg, "leg-\(index+1)")
                }
            case "WALK":
                DirectionLegWalkView(leg: leg).onTapGesture {
                    onTap?(leg, "leg-\(index+1)")
                }
            default:
                DirectionLegUnknownView(leg: leg).onTapGesture {
                    onTap?(leg, "leg-\(index+1)")
                }
            }
        }
    }
}

#Preview {
    ItineraryLegsView(itinerary: PreviewHelpers.buildItin(legsCount: 3))
}
