/*
 * Copyright (C) Open Transit Software Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import CoreLocation
import MapKit
import OTPKit
import SwiftUI

@main
struct OTPKitDemoApp: App {
    @State private var hasCompletedOnboarding = false
    @State private var otpConfiguration: OTPConfiguration?
    @State private var mapProvider: OTPMapProvider?

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding, 
               let config = otpConfiguration,
               let provider = mapProvider {
                let apiService = RestAPIService(baseURL: config.otpServerURL)
                
                ZStack {
                    // The external map view that OTPKit will control
                    MKMapViewRepresentable(
                        mapProvider: .constant(provider),
                        initialRegion: MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
                            latitudinalMeters: 10000,
                            longitudinalMeters: 10000
                        ),
                        showsUserLocation: true
                    )
                    .ignoresSafeArea()
                    
                    // OTPKit UI overlay
                    OTPView(
                        otpConfig: config, 
                        apiService: apiService,
                        mapProvider: provider
                    )
                }
            } else {
                OnboardingView(
                    hasCompletedOnboarding: $hasCompletedOnboarding,
                    otpConfiguration: $otpConfiguration,
                    mapProvider: $mapProvider
                )
            }
        }
    }
}

#Preview("Onboarding") {
    OnboardingView(
        hasCompletedOnboarding: .constant(false),
        otpConfiguration: .constant(nil),
        mapProvider: .constant(nil)
    )
}
