//
//  RecentLocationsSheet.swift
//  OTPKit
//
//  Created by Manu on 2025-07-08.
//

import SwiftUI

/// A sheet that displays the user's recently selected locations.
struct RecentLocationsSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var recentLocations: [Location] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    let selectedMode: LocationMode
    let onLocationSelected: (Location) -> Void

    var body: some View {
        VStack(spacing: 0) {
            PageHeaderView(text: "Recent Locations") {
                dismiss()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if isLoading {
                ProgressView("Loading recent locations...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if recentLocations.isEmpty {
                emptyStateView()
            } else {
                locationsList()
            }
        }
        .onAppear {
            loadRecentLocations()
        }
    }

    private func locationsList() -> some View {
        List(recentLocations, id: \.id) { location in
            Button(action: {
                onLocationSelected(location)
                // Update the recent location date when selected
                _ = UserDefaultsServices.shared.updateRecentLocations(location)
                dismiss()
            }) {
                LocationRowView(location: location, showClock: true)
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
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("No Recent Locations")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your recently visited locations will appear here as you use the app.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadRecentLocations() {
        isLoading = true

        switch UserDefaultsServices.shared.getRecentLocations() {
        case .success(let locations):
            recentLocations = locations
            errorMessage = nil
        case .failure(let error):
            recentLocations = []
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func deleteLocation(_ location: Location) {
        // Optimistically remove from UI first
        recentLocations.removeAll { $0.id == location.id }

        // Then delete from UserDefaults
        let result = UserDefaultsServices.shared.deleteRecentLocation(with: location.id)
        switch result {
        case .success:
            // Successfully deleted
            break
        case .failure(let error):
            print("Failed to delete recent location: \(error.localizedDescription)")
            // Reload data to restore UI state if deletion failed
            loadRecentLocations()
        }
    }
}
