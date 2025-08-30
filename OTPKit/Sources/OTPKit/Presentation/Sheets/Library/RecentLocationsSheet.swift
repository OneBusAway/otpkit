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
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading recent locations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if recentLocations.isEmpty {
                    emptyStateView()
                } else {
                    locationsList()
                }
            }
            .navigationTitle("Recent Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadRecentLocations()
            }
        }
    }

    private func locationsList() -> some View {
        List(recentLocations, id: \.id) { location in
            Button(action: {
                onLocationSelected(location)
                // Update the recent location date when selected
                _ = UserDefaultsServices.shared.updateRecentLocations(location)
                dismiss()
            }, label: {
                LocationRowView(location: location, showClock: true)
            })
            .foregroundStyle(.foreground)
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
}
