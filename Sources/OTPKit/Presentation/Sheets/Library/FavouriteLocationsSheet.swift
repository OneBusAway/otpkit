//
//  FavouriteLocationsSheet.swift
//  OTPKit
//
//  Created by Manu on 2025-07-08.
//
import SwiftUI

/// A sheet that displays a list of user's favourite transit locations.
/// Users can select a location to set as origin/destination or dismiss the sheet.
struct FavouriteLocationsSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var favouriteLocations: [Location] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    @Environment(\.otpTheme) private var theme

    let selectedMode: LocationMode
    let onLocationSelected: (Location) -> Void

    var body: some View {
        VStack(spacing: 0) {
            PageHeaderView(text: "Favourite Stops") {
                dismiss()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if isLoading {
                ProgressView("Loading favourites...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if favouriteLocations.isEmpty {
                emptyStateView()
            } else {
                locationsList()
            }
        }
        .onAppear {
            loadFavouriteLocations()
        }
    }

    private func locationsList() -> some View {
        List(favouriteLocations, id: \.id) { location in
            Button(action: {
                onLocationSelected(location)
                dismiss()
            }) {
                LocationRowView(location: location, showHeart: true)
            }
            .foregroundStyle(.foreground)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    deleteLocation(location)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 40))
                .foregroundColor(theme.primaryColor)

            Text("No Favourite Stops")
                .font(.title2)
                .fontWeight(.semibold)

            Text("You haven't saved any favourite locations yet. Start by selecting locations on the map!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadFavouriteLocations() {
        isLoading = true

        switch UserDefaultsServices.shared.getFavoriteLocationsData() {
        case .success(let locations):
            favouriteLocations = locations
            errorMessage = nil
        case .failure(let error):
            favouriteLocations = []
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func deleteLocation(_ location: Location) {
        // Optimistically remove from UI first
        favouriteLocations.removeAll { $0.id == location.id }

        // Then delete from UserDefaults
        let result = UserDefaultsServices.shared.deleteFavoriteLocationData(with: location.id)
        switch result {
        case .success:
            // Successfully deleted
            break
        case .failure(let error):
            print("Failed to delete favorite location: \(error.localizedDescription)")
            // Reload data to restore UI state if deletion failed
            loadFavouriteLocations()
        }
    }
}
