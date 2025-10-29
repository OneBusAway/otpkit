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
            DirectionLegView(leg: leg).onTapGesture {
                onTap?(leg, "leg-\(index+1)")
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        ItineraryLegsView(itinerary: PreviewHelpers.buildItin(legsCount: 3))
    }
    .padding(20)
}
