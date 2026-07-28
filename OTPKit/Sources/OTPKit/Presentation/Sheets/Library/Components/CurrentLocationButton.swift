//
//  CurrentLocationButton.swift
//  OTPKit
//
//  Created by Manu on 2025-08-28.
//

import SwiftUI
import CoreLocation

/// A prominent button for selecting the user's current location
struct CurrentLocationButton: View {
    let onLocationSelected: (Location) -> Void

    @Environment(\.otpTheme) private var theme
    @StateObject private var locationManager = LocationManager.shared
    @State private var isGettingLocation = false
    @State private var showError = false

    var body: some View {
        Button(action: handleCurrentLocationTap) {
            HStack(spacing: 16) {
                // Icon
                Group {
                    if isGettingLocation {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if showError {
                        Image(systemName: "location.slash")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(theme.primaryColor)
                    }
                }
                .frame(width: 24)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(buttonSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isGettingLocation || isLocationDenied)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .onReceive(locationManager.$authorizationStatus) { status in
            if status == .denied || status == .restricted {
                showError = true
            } else {
                showError = false
            }
        }
    }

    // MARK: - Computed Properties

    private var buttonTitle: String {
        if isGettingLocation {
            return OTPLoc("current_location.getting", comment: "Title while acquiring the device's location")
        } else if showError {
            return isLocationDenied
                ? OTPLoc("current_location.access_denied", comment: "Title when location permission is denied")
                : OTPLoc("current_location.unavailable", comment: "Title when the location can't be determined")
        } else {
            return OTPLoc("current_location.use_current", comment: "Title of the use-current-location button")
        }
    }

    private var buttonSubtitle: String {
        if isGettingLocation {
            return OTPLoc("current_location.getting_subtitle", comment: "Subtitle while acquiring the device's location")
        } else if showError {
            return isLocationDenied
                ? OTPLoc("current_location.enable_in_settings", comment: "Subtitle when location permission is denied")
                : OTPLoc("current_location.unable_subtitle", comment: "Subtitle when the location can't be determined")
        } else {
            return OTPLoc("current_location.default_subtitle", comment: "Subtitle of the use-current-location button")
        }
    }

    private var isLocationDenied: Bool {
        locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted
    }

    // MARK: - Actions

    private func handleCurrentLocationTap() {
        Task {
            await getCurrentLocation()
        }
    }

    @MainActor
    private func getCurrentLocation() async {
        // Check permission status first
        switch locationManager.authorizationStatus {
        case .notDetermined:
            // Request permission first
            locationManager.requestLocationPermission()
            return
        case .denied, .restricted:
            showError = true
            return
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            break
        }

        isGettingLocation = true
        showError = false

        if let location = await locationManager.getCurrentLocation() {
            onLocationSelected(location)
        } else {
            showError = true
            // Hide error after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showError = false
            }
        }

        isGettingLocation = false
    }
}

// MARK: - Preview

#Preview {
    CurrentLocationButton { location in
        print("Selected location: \(location.title)")
    }
    .padding()
}
