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

    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel
    @Environment(\.dismiss) var dismiss

    public var body: some View {
        let unknownLocation = OTPLoc("common.unknown_location", comment: "Fallback for a location with no name")

        return NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8.0, pinnedViews: [.sectionFooters]) {
                    Section {
                        Group {
                            DirectionLegOriginDestinationView(
                                title: OTPLoc("directions.start", comment: "Label for the start of a trip"),
                                description: origin?.title ?? unknownLocation
                            )
                            .padding(.horizontal, 20)

                            Divider()

                            ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { _, leg in
                                DirectionLegView(leg: leg).onTapGesture {
                                    print("boop")
                                }
                                .padding(.horizontal, 20)
                                Divider()
                            }

                            DirectionLegOriginDestinationView(
                                title: OTPLoc("map.destination", comment: "The destination of a trip"),
                                description: destination?.title ?? unknownLocation
                            )
                            .padding(.horizontal, 20)
                        }
                        .padding(2)
                    } footer: {
                        ZStack {
                            Rectangle()
                                .fill(.thinMaterial)

                            Button(OTPLoc("directions.start_navigation", comment: "Starts turn-by-turn navigation")) {
                                tripPlannerVM.handleTripStarted(itinerary)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(destination?.title ?? OTPLoc("map.destination", comment: "The destination of a trip"))
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(OTPLoc("common.close", comment: "Close button"), systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ItineraryDetailsView(origin: PreviewHelpers.createOrigin(), destination: PreviewHelpers.createDestination(), itinerary: PreviewHelpers.buildItin(legsCount: 3))
        .environmentObject(PreviewHelpers.mockTripPlannerViewModel())
}
