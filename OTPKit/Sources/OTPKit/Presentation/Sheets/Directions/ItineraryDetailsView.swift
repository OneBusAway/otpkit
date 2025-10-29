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
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8.0, pinnedViews: [.sectionFooters]) {
                    Section {
                        Group {
                            DirectionLegOriginDestinationView(
                                title: "Start",
                                description: origin?.title ?? "Unknown"
                            )
                            .padding(.horizontal, 20)

                            Divider()

                            ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, leg in
                                DirectionLegView(leg: leg).onTapGesture {
                                    print("boop")
                                }
                                .padding(.horizontal, 20)
                                Divider()
                            }

                            DirectionLegOriginDestinationView(
                                title: "Destination",
                                description: destination?.title ?? "Unknown"
                            )
                            .padding(.horizontal, 20)
                        }
                        .padding(2)
                    } footer: {
                        ZStack {
                            Rectangle()
                                .fill(.thinMaterial)

                            Button("Start Navigation") {
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
            .navigationTitle(destination?.title ?? "Destination")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") {
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
