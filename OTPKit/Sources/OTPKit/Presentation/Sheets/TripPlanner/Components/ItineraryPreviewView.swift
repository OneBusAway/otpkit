//
//  ItineraryPreviewView.swift
//
//
//  Created by Aaron Brethorst on 10/21/25.
//

import SwiftUI
import Flow

/// Renders an entire Itinerary preview for a trip.
struct ItineraryPreviewView: View {
    @Environment(\.otpTheme) private var theme

    let itinerary: Itinerary
    let onItinerarySelected: (Itinerary) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(Formatters.formatTimeDuration(itinerary.duration))
                    .font(.title)
                    .fontWeight(.semibold)

                HStack(spacing: 2) {
                    Text("ETA:")
                    Text(Formatters.formatDateToTime(itinerary.endTime))
                }

                legsFlow(itinerary: itinerary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }

            // Go button
            goButton(itinerary: itinerary)
        }
        .padding(8)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func goButton(itinerary: Itinerary) -> some View {
        Button(action: {
            onItinerarySelected(itinerary)
        }, label: {
            VStack(spacing: 2) {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Go")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(theme.primaryColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        })
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func legView(for leg: Leg) -> some View {
        if leg.walkMode {
            ItineraryLegWalkView(leg: leg)
        } else if let routeType = leg.routeType, routeType != .nonTransit {
            ItineraryLegVehicleView(leg: leg)
        } else {
            ItineraryLegUnknownView(leg: leg)
        }
    }

    @ViewBuilder
    private func legsFlow(itinerary: Itinerary) -> some View {
        HFlow(alignment: .center, spacing: 4) {
            ForEach(Array(zip(itinerary.relevantLegs.indices, itinerary.relevantLegs)), id: \.1) { index, leg in
                legView(for: leg)
                if index < itinerary.relevantLegs.count - 1 {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 8))
                }
            }
        }
    }
}

#Preview {
    ItineraryPreviewView(itinerary: PreviewHelpers.buildItin(legsCount: 3)) { _ in }
}
