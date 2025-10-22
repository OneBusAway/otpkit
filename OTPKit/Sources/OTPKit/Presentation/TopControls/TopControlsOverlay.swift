//
//  TopControlsOverlay.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI

/// Top controls with Apple Maps-style design for trip planning
/// Clean, minimal interface following Apple's design system
struct TopControlsOverlay: View {
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel
    @Binding var selectedMode: LocationMode
    @Environment(\.otpTheme) private var theme

    var body: some View {
        VStack(spacing: 20) {
            routeInputCard
            actionButtons
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Route Input Card

    private var routeInputCard: some View {
        VStack(spacing: 0) {
            // "From" location
            RouteInputRow(
                icon: "record.circle",
                iconColor: .primary,
                title: "From",
                subtitle: tripPlannerVM.selectedOriginTitle,
                hasLocation: tripPlannerVM.selectedOrigin != nil
            ) {
                tripPlannerVM.present(.search(.origin))
            }

            // Divider with connecting line
            routeDivider

            // "To" Location
            RouteInputRow(
                icon: "location",
                iconColor: .primary,
                title: "To",
                subtitle: tripPlannerVM.selectedDestinationTitle,
                hasLocation: tripPlannerVM.selectedDestination != nil
            ) {
                tripPlannerVM.present(.search(.destination))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }

    private var routeDivider: some View {
        HStack {
            Rectangle()
                .fill(.clear)
                .frame(width: 18)

            // Connecting line
            Rectangle()
                .fill(.tertiary)
                .frame(width: 2, height: 12)

            Spacer()
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 14) {
            Button(action: { tripPlannerVM.present(.advancedOptions) }) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                    Text("Options")
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)

            Button(action: tripPlannerVM.planTrip) {
                HStack(spacing: 8) {
                    if tripPlannerVM.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right")
                    }
                    Text("Find Routes")
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!tripPlannerVM.canPlanTrip)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        TopControlsOverlay(selectedMode: .constant(.destination))
            .padding(8)
            .environmentObject(PreviewHelpers.mockTripPlannerViewModel())
    }
    .background(Color(.systemGroupedBackground))
    .frame(height: 50)
}
