//
//  LibraryView.swift
//  OTPKit
//
//  Created by Manu on 2025-08-28.
//

import SwiftUI

/// A redesigned library view for managing user locations
struct LibraryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.otpTheme) private var theme
    @EnvironmentObject private var tripPlannerVM: TripPlannerViewModel
    @State private var showingFavourites = false
    @State private var showingRecents = false

    let selectedMode: LocationMode

    var body: some View {
        VStack(spacing: 0) {
            PageHeaderView(text: "Library") {
                dismiss()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ScrollView(.vertical) {
                VStack(spacing: 24) {
                    CurrentLocationButton { location in
                        handleLocationSelection(location)
                    }
                    .padding(.horizontal, 16)

                    FavoritesSectionView(
                        selectedMode: selectedMode,
                        onLocationSelected: { location in
                            handleLocationSelection(location)
                        },
                        onMoreTapped: {
                            showingFavourites = true
                        }
                    )
                    .padding(.horizontal, 16)

                    RecentsSectionView(
                        selectedMode: selectedMode,
                        onLocationSelected: { location in
                            handleLocationSelection(location)
                        },
                        onMoreTapped: {
                            showingRecents = true
                        }
                    )
                    .padding(.horizontal, 16)

                    Spacer(minLength: 50)
                }
                .padding(.top, 16)
            }
        }
        .sheet(isPresented: $showingFavourites) {
            FavouriteLocationsSheet(selectedMode: selectedMode, onLocationSelected: handleLocationSelection)
        }
        .sheet(isPresented: $showingRecents) {
            RecentLocationsSheet(selectedMode: selectedMode, onLocationSelected: handleLocationSelection)
        }
    }

    /// Handles location selection for the current mode
    private func handleLocationSelection(_ location: Location) {
        tripPlannerVM.handleLocationSelection(location, for: selectedMode)
    }
}

#Preview {
    LibraryView(selectedMode: .destination)
        .environmentObject(PreviewHelpers.mockTripPlannerViewModel())
}
