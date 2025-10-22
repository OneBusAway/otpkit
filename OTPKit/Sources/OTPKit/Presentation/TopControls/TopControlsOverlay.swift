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
            // Main route input card
            routeInputCard

            // Action buttons
            actionButtons
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Route Input Card

    private var routeInputCard: some View {
        VStack(spacing: 0) {
            // From location
            routeInputRow(
                icon: "record.circle",
                iconColor: .blue,
                title: "From",
                subtitle: tripPlannerVM.selectedOriginTitle,
                hasLocation: tripPlannerVM.selectedOrigin != nil,
                action: { tripPlannerVM.present(.search(.origin)) }
            )

            // Divider with connecting line
            routeDivider

            // To location
            routeInputRow(
                icon: "location",
                iconColor: .red,
                title: "To",
                subtitle: tripPlannerVM.selectedDestinationTitle,
                hasLocation: tripPlannerVM.selectedDestination != nil,
                action: { tripPlannerVM.present(.search(.destination)) }
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }

    private func routeInputRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        hasLocation: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon with improved sizing
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)

                // Text content with better hierarchy
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(hasLocation ? .primary : theme.primaryColor)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                // Chevron with consistent styling
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.primaryColor)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var routeDivider: some View {
        HStack(spacing: 0) {
            // Left side spacer to align with icon center
            HStack {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 24)

                // Connecting line with improved styling
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 2, height: 12)

                Spacer()
            }
            .padding(.leading, 18)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 14) {
            // Options button with Apple-style design
            Button(action: { tripPlannerVM.present(.advancedOptions) }) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Options")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .tint(.secondary)

            Button(action: tripPlannerVM.planTrip) {
                HStack(spacing: 8) {
                    if tripPlannerVM.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text("Find Routes")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
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
