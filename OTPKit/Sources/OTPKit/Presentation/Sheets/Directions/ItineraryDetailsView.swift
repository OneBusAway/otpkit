//
//  ItineraryDetailsView.swift
//  OTPKit
//
//  Created by Aaron Brethorst on 10/26/25.
//

import SwiftUI
import CoreLocation

struct ItineraryDetailsView: View {
    let origin: Location?
    let destination: Location?
    let itinerary: Itinerary

    @Environment(\.dismiss) var dismiss

    public var body: some View {
        List {
            Section {
                PageHeaderView(text: destination?.title ?? "Destination") {
                    dismiss()
                }
            }
            .listRowBackground(Color.clear)

            Section {
                DirectionLegOriginDestinationView(
                    title: "Start",
                    description: origin?.title ?? "Unknown"
                )

                ItineraryLegsView(itinerary: itinerary)

                DirectionLegOriginDestinationView(
                    title: "Destination",
                    description: destination?.title ?? "Unknown"
                )
            }
            .listRowBackground(Color.clear)
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .listStyle(PlainListStyle())
    }
}
