//
//  PagedDirectionsView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 10/28/25.
//

import SwiftUI

struct PagedDirectionsView: View {
    let itinerary: Itinerary
    let onTap: LegIDTapHandler?

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ItineraryLegsView(itinerary: itinerary, onTap: onTap)
                    .frame(width: proxy.size.width)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
        }
    }
}

#Preview {
    PagedDirectionsView(
        itinerary: PreviewHelpers.buildItin(legsCount: 3)
    ) { leg, _ in
        print("Leg tapped: \(leg)")
    }
}
