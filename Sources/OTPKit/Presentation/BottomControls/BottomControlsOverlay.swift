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
            // Transport Mode and DateTime Selection
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    ForEach(transportModes, id: \.mode) { config in
                        TransportModeButton(
                            mode: config.mode,
                            icon: config.icon,
                            isSelected: tripPlannerVM.selectedTransportMode == config.mode
                        ) {
                            tripPlannerVM.selectTransportMode(config.mode)
                        }
                    }

                    Button(action: {
                        tripPlannerVM.present(.search)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14, weight: .medium))
                            LocalizedText("bottom.search")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        .frame(height: 36)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 4)
            }

            // Location selection buttons stacked vertically
            VStack(spacing: 8) {
                LocationButton(
                    title: Localization.string("bottom.from"),
                    subtitle: tripPlannerVM.selectedOrigin?.title ?? Localization.string("bottom.current_location"),
                    icon: "location.fill",
                    isSelected: selectedMode == .origin,
                    hasLocation: tripPlannerVM.selectedOrigin != nil,
                    action: {
                        selectedMode = .origin
                    }
                )
                LocationButton(
                    title: Localization.string("bottom.to"),
                    subtitle: tripPlannerVM.selectedDestination?.title ?? Localization.string("bottom.choose_destination"),
                    icon: "mappin",
                    isSelected: selectedMode == .destination,
                    hasLocation: tripPlannerVM.selectedDestination != nil,
                    action: {
                        selectedMode = .destination
                    }
                )
            }

            // Advanced Options Button
            Button(action: {
                tripPlannerVM.present(.advancedOptions)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: hasAdvancedOptionsSet ? "ellipsis.circle.fill" : "ellipsis.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.primaryColor)
                    LocalizedText("bottom.advanced_options")
                        .font(.system(size: 14, weight: .medium))

                    if hasAdvancedOptionsSet {
                        Circle()
                            .fill(theme.primaryColor)
                            .frame(width: 6, height: 6)
                    }
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(hasAdvancedOptionsSet ? theme.primaryColor.opacity(0.1) : Color(.systemGray6))
                .cornerRadius(8)
            }

            // Action buttons
            HStack(spacing: 8) {
                // More Options Button
                Button(action: tripPlannerVM.showLocationOptions) {
                    HStack(spacing: 6) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .medium))
                        LocalizedText("bottom.options")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                // Plan Trip Button
                Button(action: tripPlannerVM.planTrip) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .medium))
                        LocalizedText("bottom.directions")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(tripPlannerVM.canPlanTrip ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        tripPlannerVM.canPlanTrip ? theme.primaryColor : Color(.systemGray5)
                    )
                    .cornerRadius(8)
                }
                .disabled(!tripPlannerVM.canPlanTrip)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: -2)
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

    private let transportModes: [(mode: TransportMode, icon: String)] = [
        (.transit, "tram.fill"),
        (.walk, "figure.walk"),
        (.bike, "bicycle"),
        (.car, "car.fill")
    ]

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
