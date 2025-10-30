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
                    VStack {
                        DirectionLegOriginDestinationView(title: "Start", description: trip.origin.title)
                            .frame(width: proxy.size.width)

                        HStack {
                            Image(systemName: "lessthan.circle.fill")
                                .symbolEffect(.wiggle.byLayer, options: .repeat(.periodic(delay: 1.0)))
                                .foregroundStyle(LinearGradient(stops: [
                                    .init(color: .accentColor.mix(with: .white, by: 0.2), location: 0.5),
                                    .init(color: .accentColor, location: 0.5),
                                ], startPoint: .top, endPoint: .bottom))
                            Text("Swipe to view each step")
                                .padding(.vertical, 8)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }

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
