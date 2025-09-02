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
    @State private var selectedRegionInfo: RegionInfo?
    @State private var mapProvider: OTPMapProvider?

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding, 
               let config = otpConfiguration,
               let regionInfo = selectedRegionInfo {
                let apiService = RestAPIService(baseURL: config.otpServerURL)
                
                ZStack {
                    // The external map view that OTPKit will control
                    MKMapViewRepresentable(
                        mapProvider: $mapProvider,
                        initialRegion: MKCoordinateRegion(
                            center: regionInfo.center,
                            latitudinalMeters: 50000,
                            longitudinalMeters: 50000
                        ),
                        showsUserLocation: true
                    )
                    .ignoresSafeArea()
                    
                    // OTPKit UI overlay - only render once we have a map provider
                    if let provider = mapProvider {
                        OTPView(
                            otpConfig: config, 
                            apiService: apiService,
                            mapProvider: provider
                        )
                    }
                }
            } else {
                OnboardingView(
                    hasCompletedOnboarding: $hasCompletedOnboarding,
                    otpConfiguration: $otpConfiguration,
                    selectedRegionInfo: $selectedRegionInfo
                )
            }
        }
    }
}

#Preview("Onboarding") {
    OnboardingView(
        hasCompletedOnboarding: .constant(false),
        otpConfiguration: .constant(nil),
        selectedRegionInfo: .constant(nil)
    )
}
