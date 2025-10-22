//
//  TripPlannerResultsView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI
import Flow

public struct TripPlannerResultsView: View {
    @Environment(\.otpTheme) private var theme
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel

    let availableItineraries: [Itinerary]
    let onItinerarySelected: (Itinerary) -> Void
    let onItineraryPreview: (Itinerary) -> Void

    enum LegViewType {
        case vehicle
        case walk
        case unknown
    }

    // MARK: - Initialization
    public init(
        availableItineraries: [Itinerary],
        onItinerarySelected: @escaping (Itinerary) -> Void = { _ in },
        onItineraryPreview: @escaping (Itinerary) -> Void = { _ in }
    ) {
        self.availableItineraries = availableItineraries
        self.onItinerarySelected = onItinerarySelected
        self.onItineraryPreview = onItineraryPreview
    }

    // MARK: - Body
    public var body: some View {
        VStack(spacing: 0) {
            if hasItineraries {
                itinerariesScrollView()
            } else {
                noItinerariesView()
            }
        }
    }

    // MARK: - View Components
    private func itinerariesScrollView() -> some View {
        LazyVStack(spacing: 8) {
            ForEach(availableItineraries, id: \.self) { itinerary in
                Button(action: {
                    onItineraryPreview(itinerary)
                }, label: {
                    itineraryRow(itinerary: itinerary)
                })
                .foregroundStyle(.foreground)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.regularMaterial)
                        .shadow(radius: 2) // ok now i made it ugly :(
                )
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.15), value: itinerary)
            }
        }
        .padding(.horizontal, 16)
    }

    private func itineraryRow(itinerary: Itinerary) -> some View {
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

    private func noItinerariesView() -> some View {
        VStack {
            Text("No trips found")
                .foregroundStyle(theme.secondaryColor)
                .padding()
        }
    }

    // MARK: - Helper Methods
    private var hasItineraries: Bool {
        !availableItineraries.isEmpty
    }

    private func getLegViewType(for leg: Leg) -> LegViewType {
        switch leg.mode.lowercased() {
        case "walk":
            return .walk
        case "bus", "train", "tram", "subway", "ferry":
            return .vehicle
        default:
            return .unknown
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

#Preview {
    let itineraries = [
        PreviewHelpers.buildItin(legsCount: 3),
        PreviewHelpers.buildItin(legsCount: 4),
    ]
    TripPlannerResultsView(availableItineraries: itineraries) { _ in
        //
    } onItineraryPreview: { _ in
        //
    }
}
