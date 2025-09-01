//
//  BottomControlsOverlay.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI

/// Bottom overlay containing transport mode selection, location inputs, and action buttons
/// Provides the main user interface for trip planning configuration
struct BottomControlsOverlay: View {
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel
    @Binding var selectedMode: LocationMode
    @Environment(\.otpTheme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            // Location selection buttons stacked vertically
            VStack(spacing: 8) {
                LocationButton(
                    title: Localization.string("bottom.from"),
                    subtitle: tripPlannerVM.selectedOriginTitle,
                    icon: "location.fill",
                    hasLocation: tripPlannerVM.selectedOrigin != nil,
                    action: {
                        tripPlannerVM.present(.search(.origin))
                    }
                )
                LocationButton(
                    title: Localization.string("bottom.to"),
                    subtitle: tripPlannerVM.selectedDestinationTitle,
                    icon: "mappin",
                    hasLocation: tripPlannerVM.selectedDestination != nil,
                    action: {
                        tripPlannerVM.present(.search(.destination))
                    }
                )
            }

            HStack(spacing: 8) {
                Button(action: {
                    tripPlannerVM.present(.advancedOptions)
                }, label: {
                    HStack(spacing: 6) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14, weight: .medium))
                        LocalizedText("bottom.advanced_options")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                })
                .controlSize(.large)
                .buttonStyle(.bordered)

                Button(action: tripPlannerVM.planTrip) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .medium))
                        LocalizedText("bottom.directions")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .disabled(!tripPlannerVM.canPlanTrip)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground).opacity(0.9))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 16)
    }

    private func formatDateTime() -> String {
        let date = tripPlannerVM.departureDate ?? Date()
        let time = tripPlannerVM.departureTime ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM d")
        let timeFormatter = DateFormatter()
        timeFormatter.setLocalizedDateFormatFromTemplate("h:mm a")

        return "\(dateFormatter.string(from: date)) \(timeFormatter.string(from: time))"
    }

    /// Checks if any advanced options are set to non-default values
    private var hasAdvancedOptionsSet: Bool {
        return tripPlannerVM.isWheelchairAccessible ||
        tripPlannerVM.maxWalkingDistance != .oneMile ||
        tripPlannerVM.timePreference != .leaveNow ||
        tripPlannerVM.routePreference != .fastestTrip
    }
}

// MARK: - Preview

import MapKit

#Preview {
    ZStack {
        Map()
        VStack {
            Spacer()
            BottomControlsOverlay(selectedMode: .constant(.destination))
                .environmentObject(PreviewHelpers.mockTripPlannerViewModel())
        }
    }
}
