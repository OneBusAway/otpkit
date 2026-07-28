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
                        title: OTPLoc("location_picker.current_location_title", comment: "Option to use the device's location"),
                        subtitle: OTPLoc("location_picker.current_location_subtitle", comment: "Describes the current location option"),
                        color: theme.primaryColor
                    ) { requestCurrentLocation() }

                    Divider().padding(.leading, 52)

                    LocationOptionButton(
                        icon: "heart.fill",
                        title: OTPLoc("location_picker.favorites_title", comment: "Option to pick a saved favorite location"),
                        subtitle: OTPLoc("location_picker.favorites_subtitle", comment: "Describes the favorites option"),
                        color: .red
                    ) { showingFavourites = true }

                    Divider().padding(.leading, 52)

                    LocationOptionButton(
                        icon: "clock.fill",
                        title: OTPLoc("location_picker.recents_title", comment: "Option to pick a recently used location"),
                        subtitle: OTPLoc("location_picker.recents_subtitle", comment: "Describes the recents option"),
                        color: theme.secondaryColor
                    ) { showingRecents = true }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle(selectedMode == .origin
                ? OTPLoc("location_picker.choose_start", comment: "Title when picking the trip's starting point")
                : OTPLoc("location_picker.choose_destination", comment: "Title when picking the trip's destination"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(OTPLoc("common.cancel", comment: "Cancel button")) { dismiss() }
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

        let currentLocation = Location.currentLocation(from: location.coordinate)

        onLocationSelected(currentLocation, selectedMode)
    }
}
