//
//  TripPlannerSheetView.swift
//  OTPKit
//
//  Created by Hilmy Veradin on 25/07/24.
//

import SwiftUI

public struct TripPlannerSheetView: View {
    @Environment(TripPlannerService.self) private var tripPlanner
    @Environment(\.dismiss) var dismiss

    // MARK: - ViewModel
    private var viewModel: TripPlannerSheetViewModel {
        TripPlannerSheetViewModel(tripPlannerService: tripPlanner)
    }

    // MARK: - Initialization
    public init() {}

    // MARK: - Body
    public var body: some View {
        VStack {
            if viewModel.hasItineraries {
                itinerariesList()
            } else {
                noItinerariesView()
            }

            cancelButton()
        }
        .alert(
            viewModel.currentError?.title ?? "Error",
            isPresented: Binding(
                get: { viewModel.showErrorAlert },
                set: { _ in viewModel.clearError() }
            )
        ) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.currentError?.errorDescription ?? "")
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
            }
        }
    }

    // MARK: - View Components

    private func itinerariesList() -> some View {
        List(viewModel.availableItineraries, id: \.self) { itinerary in
            Button(action: {
                viewModel.selectItinerary(itinerary)
                dismiss()
            }) {
                itineraryRow(itinerary: itinerary)
            }
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
            Text(viewModel.formatDuration(itinerary))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.foreground)

            Text(viewModel.formatStartTime(itinerary))
                .foregroundStyle(.gray)

            legsFlow(itinerary: itinerary)
        }
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
        switch viewModel.getLegViewType(for: leg) {
        case .vehicle:
            ItineraryLegVehicleView(leg: leg)
        case .walk:
            ItineraryLegWalkView(leg: leg)
        case .unknown:
            ItineraryLegUnknownView(leg: leg)
        }
    }

    private func previewButton(itinerary: Itinerary) -> some View {
        Button(action: {
            viewModel.previewItinerary(itinerary)
            dismiss()
        }) {
            Text("Preview")
                .padding(30)
                .background(Color.green)
                .foregroundStyle(.foreground)
                .fontWeight(.bold)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func noItinerariesView() -> some View {
        Text(viewModel.noTripPlannerMessage)
            .padding()
    }

    private func cancelButton() -> some View {
        Button(action: {
            viewModel.cancelTripPlanning()
            dismiss()
        }) {
            Text("Cancel")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundStyle(.foreground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
        }
    }
}

#Preview {
    TripPlannerSheetView()
}
