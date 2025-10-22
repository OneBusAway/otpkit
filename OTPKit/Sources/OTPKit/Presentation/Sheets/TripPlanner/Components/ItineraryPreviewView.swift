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
            // Route info
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text(formatDuration(itinerary))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Text(formatStartTime(itinerary))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Transport modes with improved layout
                legsFlow(itinerary: itinerary)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        if leg.routeType == nil {
            ItineraryLegUnknownView(leg: leg)
        } else {
            if leg.routeType! == .nonTransit {
                ItineraryLegWalkView(leg: leg)
            } else {
                ItineraryLegVehicleView(leg: leg)
            }
        }
    }

    private func legsFlow(itinerary: Itinerary) -> some View {
        HFlow(alignment: .center, spacing: 4) {
            ForEach(Array(zip(itinerary.legs.indices, itinerary.legs)), id: \.1) { index, leg in
                legView(for: leg)
                if index < itinerary.legs.count - 1 {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 8))
                }
            }
        }
    }

    private func formatDuration(_ itinerary: Itinerary) -> String {
        let duration = Int(itinerary.duration / 60) // Convert seconds to minutes
        return "\(duration) min"
    }

    private func formatStartTime(_ itinerary: Itinerary) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: itinerary.startTime)
    }
}
