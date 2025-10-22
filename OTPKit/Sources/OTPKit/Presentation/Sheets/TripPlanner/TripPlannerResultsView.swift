//
//  TripPlannerResultsView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI

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
                    ItineraryPreviewView(itinerary: itinerary, onItinerarySelected: onItinerarySelected)
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
