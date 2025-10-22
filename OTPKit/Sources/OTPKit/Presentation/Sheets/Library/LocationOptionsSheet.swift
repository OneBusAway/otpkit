//
//  LocationOptionsSheet.swift
//  OTPKit
//
//  Created by Manu on 2025-07-08.
//

import SwiftUI
import CoreLocation
import OSLog

/// A bottom sheet that presents options to set a location:
/// - Use current GPS location
/// - Pick from favorite locations
/// - Choose from recently used locations
struct LocationOptionsSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.otpTheme) private var theme
    @State private var locationManager = CLLocationManager()
    @State private var showingFavourites = false
    @State private var showingRecents = false

    let selectedMode: LocationMode
    let onLocationSelected: OnLocationSelectedHandler

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                VStack(spacing: 0) {
                    LocationOptionButton(
                        icon: "location.fill",
                        title: "Current Location",
                        subtitle: "Use your current GPS location",
                        color: theme.primaryColor
                    ) { requestCurrentLocation() }

                    Divider().padding(.leading, 52)

                    LocationOptionButton(
                        icon: "heart.fill",
                        title: "Favorites",
                        subtitle: "Choose from your saved places",
                        color: .red
                    ) { showingFavourites = true }

                    Divider().padding(.leading, 52)

                    LocationOptionButton(
                        icon: "clock.fill",
                        title: "Recents",
                        subtitle: "View your recent locations",
                        color: theme.secondaryColor
                    ) { showingRecents = true }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(selectedMode == .origin ? "Choose Start" : "Choose Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingFavourites) {
            FavouriteLocationsSheet(selectedMode: selectedMode, onLocationSelected: onLocationSelected)
        }
        .sheet(isPresented: $showingRecents) {
            RecentLocationsSheet(selectedMode: selectedMode, onLocationSelected: onLocationSelected)
        }
    }

    private func requestCurrentLocation() {
        locationManager.requestWhenInUseAuthorization()

        guard let location = locationManager.location else {
            Logger.main.error("Current location not available")
            return
        }

        let currentLocation = Location(
            title: "Current Location",
            subTitle: "Your current GPS location",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        onLocationSelected(currentLocation, selectedMode)
    }
}
