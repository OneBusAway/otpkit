//
//  TripPlannerResultsView.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI

public struct TripPlannerResultsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.otpTheme) private var theme

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
        VStack {
            if hasItineraries {
                itinerariesList()
            } else {
                noItinerariesView()
            }

            cancelButton()
        }
    }

    // MARK: - View Components
    private func itinerariesList() -> some View {
        List(availableItineraries, id: \.self) { itinerary in
            Button(action: {
                onItinerarySelected(itinerary)
                dismiss()
            }, label: {
                itineraryRow(itinerary: itinerary)
            })
            .foregroundStyle(.foreground)
        }
    }

    private func itineraryRow(itinerary: Itinerary) -> some View {
        HStack(spacing: 20) {
            itineraryInfo(itinerary: itinerary)
            previewButton(itinerary: itinerary)
        }
    }

    private func itineraryInfo(itinerary: Itinerary) -> some View {
        VStack(alignment: .leading) {
            Text(formatDuration(itinerary))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.foreground)

            Text(formatStartTime(itinerary))
                .foregroundStyle(theme.secondaryColor)

            legsFlow(itinerary: itinerary)
        }
    }

    private func previewButton(itinerary: Itinerary) -> some View {
        Button(action: {
            onItineraryPreview(itinerary)
            dismiss()
        }, label: {
            Text("Preview")
                .padding(30)
                .background(theme.primaryColor)
                .foregroundStyle(.white)
                .fontWeight(.bold)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        })
    }

    private func legsFlow(itinerary: Itinerary) -> some View {
        FlowLayout {
            ForEach(Array(zip(itinerary.legs.indices, itinerary.legs)), id: \.1) { index, leg in
                legView(for: leg)

                if index < itinerary.legs.count - 1 {
                    VStack {
                        Image(systemName: "chevron.right.circle.fill")
                            .frame(width: 8, height: 16)
                    }
                    .frame(height: 40)
                }
            }
        }
    }

    @ViewBuilder
    private func legView(for leg: Leg) -> some View {
        switch getLegViewType(for: leg) {
        case .vehicle:
            ItineraryLegVehicleView(leg: leg)
        case .walk:
            ItineraryLegWalkView(leg: leg)
        case .unknown:
            ItineraryLegUnknownView(leg: leg)
        }
    }

    private func noItinerariesView() -> some View {
        VStack {
            Text("No trips found")
                .foregroundStyle(theme.secondaryColor)
                .padding()
        }
    }

    private func cancelButton() -> some View {
        Button("Cancel") {
            dismiss()
        }
        .padding()
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
