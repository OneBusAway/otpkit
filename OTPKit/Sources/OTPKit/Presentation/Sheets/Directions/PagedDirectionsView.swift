//
//  PagedDirectionsView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 10/28/25.
//

import SwiftUI

struct PagedDirectionsView: View {
    let trip: Trip
    let onTap: LegIDTapHandler?

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    DirectionLegOriginDestinationView(title: "Start", description: trip.origin.title)
                        .frame(width: proxy.size.width)
                    ForEach(Array(trip.itinerary.legs.enumerated()), id: \.offset) { index, leg in
                        DirectionLegView(leg: leg)
                            .padding(.horizontal, 16)
                            .frame(width: proxy.size.width)
                            .onTapGesture {
                                onTap?(leg, "leg-\(index+1)")
                            }
                    }
                    DirectionLegOriginDestinationView(title: "End", description: trip.destination.title)
                        .frame(width: proxy.size.width)

                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
        }
    }
}

#Preview {
    let trip = Trip(
        origin: PreviewHelpers.createOrigin(),
        destination: PreviewHelpers.createDestination(),
        itinerary: PreviewHelpers.buildItin(legsCount: 3)
    )

    PagedDirectionsView(trip: trip) { leg, _ in
        print("Leg tapped: \(leg)")
    }
}
