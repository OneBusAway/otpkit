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

import Combine
import Foundation
import OTPKit
import SwiftUI

// swiftlint:disable function_parameter_count

// Define the ViewModel as an observable object
final class TripPlannerViewModel: ObservableObject {
    // Published property to update the view
    @Published var planResponse: OTPResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = RestAPI(
        baseURL: URL(string: "https://otp.prod.sound.obaweb.org/otp/routers/default/")!
    )

    // Function to fetch the plan
    func fetchTripPlan(
        fromPlace: String,
        toPlace: String,
        time: String,
        date: String,
        mode: String,
        arriveBy: Bool,
        maxWalkDistance: Int,
        wheelchair: Bool
    ) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await apiClient.fetchPlan(
                    fromPlace: fromPlace,
                    toPlace: toPlace,
                    time: time,
                    date: date,
                    mode: mode,
                    arriveBy: arriveBy,
                    maxWalkDistance: maxWalkDistance,
                    wheelchair: wheelchair
                )
                DispatchQueue.main.async {
                    self.planResponse = response
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// swiftlint:enable function_parameter_count
