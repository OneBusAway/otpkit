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
    @State private var errorMessage: String?
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
                errorMessage = "Location access denied"
                showError = true
            } else {
                showError = false
            }
        }
    }

    // MARK: - Computed Properties

    private var buttonTitle: String {
        if isGettingLocation {
            return "Getting Location..."
        } else if showError {
            return isLocationDenied ? "Location Access Denied" : "Location Unavailable"
        } else {
            return "Use Current Location"
        }
    }

    private var buttonSubtitle: String {
        if isGettingLocation {
            return "Please wait while we get your location"
        } else if showError {
            return isLocationDenied ? "Enable location access in Settings" : "Unable to get your current location"
        } else {
            return "Get directions from where you are now"
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
            errorMessage = "Unable to get current location"
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
