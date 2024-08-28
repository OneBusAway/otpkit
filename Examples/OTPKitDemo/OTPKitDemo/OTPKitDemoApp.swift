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
    @State private var selectedRegionURL: URL?
    @State private var tripPlannerService: TripPlannerService?

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding, let service = tripPlannerService {
                MapView()
                    .environment(service)
                    .environment(OriginDestinationSheetEnvironment())
            } else {
                OnboardingView(
                    hasCompletedOnboarding: $hasCompletedOnboarding,
                    selectedRegionURL: $selectedRegionURL,
                    tripPlannerService: $tripPlannerService
                )
            }
        }
    }
}
