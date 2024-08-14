//
//  TripPlannerSheetView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 25/07/24.
//

import SwiftUI

public struct TripPlannerSheetView: View {
    @EnvironmentObject private var tripPlanner: TripPlannerService
    @Environment(\.dismiss) var dismiss

    public init() {}

    private func generateLegView(leg: Leg) -> some View {
        Group {
            switch leg.mode {
            case "BUS", "TRAM":
                ItineraryLegVehicleView(leg: leg)
            case "WALK":
                ItineraryLegWalkView(leg: leg)
            default:
                ItineraryLegUnknownView(leg: leg)
            }
        }
    }

    public var body: some View {
        VStack {
            if let itineraries = tripPlanner.planResponse?.plan?.itineraries {
                List(itineraries, id: \.self) { itinerary in
                    Button(action: {
                        tripPlanner.selectedItinerary = itinerary
                        tripPlanner.planResponse = nil
                        dismiss()
                    }, label: {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text(Formatters.formatTimeDuration(itinerary.duration))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.foreground)
                                Text("Bus scheduled at \(Formatters.formatDateToTime(itinerary.startTime))")
                                    .foregroundStyle(.gray)

                                FlowLayout {
                                    ForEach(Array(zip(itinerary.legs.indices, itinerary.legs)), id: \.1) { index, leg in

                                        generateLegView(leg: leg)

                                        if index < itinerary.legs.count - 1 {
                                            VStack {
                                                Image(systemName: "chevron.right.circle.fill")
                                                    .frame(width: 8, height: 16)
                                            }.frame(height: 40)
                                        }
                                    }
                                }
                            }

                            Button(action: {
                                tripPlanner.selectedItinerary = itinerary
                                tripPlanner.planResponse = nil
                                tripPlanner.adjustOriginDestinationCamera()
                                dismiss()
                            }, label: {
                                Text("Preview")
                                    .padding(30)
                                    .background(Color.green)
                                    .foregroundStyle(.foreground)
                                    .fontWeight(.bold)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            })
                        }

                    })
                    .foregroundStyle(.foreground)
                }
            } else {
                Text("Can't find trip planner. Please try another pin point")
            }

            Button(action: {
                tripPlanner.resetTripPlanner()
                dismiss()
            }, label: {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundStyle(.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
            })
        }
    }
}

#Preview {
    TripPlannerSheetView()
        .environmentObject(PreviewHelpers.buildTripPlannerService())
}
