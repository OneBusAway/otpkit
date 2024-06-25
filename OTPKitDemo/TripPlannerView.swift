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

import SwiftUI

struct TripPlannerView: View {
    @EnvironmentObject var viewModel: TripPlannerViewModel

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()

                        .progressViewStyle(CircularProgressViewStyle())
                        .navigationTitle("Fetching Plan")
                } else if let plan = viewModel.planResponse?.plan {
                    Text("Plan Retrieved")
                    Text("From: \(plan.from.name)")
                    Text("To: \(plan.to.name)")

                    Text("Itineraries:")
                    ForEach(plan.itineraries, id: \.self) { i in
                        Text("Transit Time \(i.duration)")
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                } else {
                    Text("Welcome to the Trip Planner")
                    Button("Fetch Trip Plan") {
                        viewModel.fetchTripPlan(
                            fromPlace: "47.6097,-122.3331",
                            toPlace: "47.6154,-122.3208",
                            time: "8:00 AM",
                            date: "05-10-2024",
                            mode: "TRANSIT,WALK",
                            arriveBy: false,
                            maxWalkDistance: 800,
                            wheelchair: false
                        )
                    }
                }
            }
        }
    }
}

// For preview and testing
struct TripPlannerView_Previews: PreviewProvider {
    static var previews: some View {
        TripPlannerView()
            .environmentObject(TripPlannerViewModel())
    }
}
