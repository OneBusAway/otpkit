//
//  BottomControlsOverlay.swift
//  OTPKit
//
//  Created by Manu on 2025-07-06.
//

import SwiftUI

/// A reusable overlay view that provides key trip-planning controls,
/// including transport mode selection, origin/destination inputs, and action buttons.
///
/// - Displays mode selection buttons (e.g. transit, walk, bike, car)
/// - Allows users to choose "From" and "To" locations
/// - Provides quick access to search and additional trip options
/// - Includes a "Directions" button to trigger trip planning
///
/// Designed to sit at the bottom of the map screen in trip planning UI.
struct BottomControlsOverlay: View {
    @EnvironmentObject private var viewModel: TripPlanningModel
    @Binding var selectedMode: LocationMode
    
    private let transportModes: [(mode: TransportMode, icon: String)] = [
        (.transit, "tram.fill"),
        (.walk, "figure.walk"),
        (.bike, "bicycle"),
        (.car, "car.fill")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Transport Mode Selection
            HStack(spacing: 12) {
                ForEach(transportModes, id: \.mode) { config in
                    TransportModeButton(
                        mode: config.mode,
                        icon: config.icon,
                        isSelected: viewModel.selectedTransportMode == config.mode
                    ) {
                        viewModel.selectTransportMode(config.mode)
                    }
                }
            }
            .padding(.horizontal, 4)

            // Location selection buttons stacked vertically
            VStack(spacing: 8) {
                LocationButton(
                    title: "From",
                    subtitle: viewModel.selectedOrigin?.title ?? "Current location",
                    icon: "location.fill",
                    isSelected: selectedMode == .origin,
                    hasLocation: viewModel.selectedOrigin != nil,
                    action: {
                        selectedMode = .origin
                    }
                )
                LocationButton(
                    title: "To",
                    subtitle: viewModel.selectedDestination?.title ?? "Choose destination",
                    icon: "mappin",
                    isSelected: selectedMode == .destination,
                    hasLocation: viewModel.selectedDestination != nil,
                    action: {
                        selectedMode = .destination
                    }
                )
            }

            // Full width Search Button
            Button(action: {
                viewModel.present(.search)
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                    Text("Search")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            // Action buttons
            HStack(spacing: 8) {
                // More Options Button
                Button(action: viewModel.showLocationOptions) {
                    HStack(spacing: 6) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .medium))
                        Text("Options")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                // Plan Trip Button
                Button(action: viewModel.planTrip) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .medium))
                        Text("Directions")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(viewModel.canPlanTrip ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        viewModel.canPlanTrip ? Color.accentColor : Color(.systemGray5)
                    )
                    .cornerRadius(8)
                }
                .disabled(!viewModel.canPlanTrip)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -4)
        )
        .padding(.horizontal, 16)
    }
}
